# `ServiceClient` State Machine (`_Call`)

This document describes the state machine implemented by
[`_Call`](lib/service_client.dart#L408-L706) in
[`lib/service_client.dart`](lib/service_client.dart). Both unary calls
([`_makeRequest`](lib/service_client.dart#L303-L319), which subscribes
immediately via `.messages.single`) and streaming calls
([`_makeStreamingRequest`](lib/service_client.dart#L325-L347), which returns
`.messages` for the caller to listen to) run on this same machine.

Every external callback — listener lifecycle hooks, `http.Client.send`
settlements, response stream events, and timers — is handled by a synchronous
method with no `await`, so `_Call`'s state cannot change mid-transition
([L404–L407](lib/service_client.dart#L404-L407)).

## Lifecycle Diagram

```mermaid
stateDiagram-v2
    WaitingForListen : _attempt = null
    WaitingForListen : before onListen

    Sending : _attempt != null, _subscription = null
    Sending : _canRetry = true

    ReadingBody : _attempt != null, _subscription = bytes
    ReadingBody : _canRetry = true

    StreamingSse : _attempt != null, _subscription = SSE
    StreamingSse : _canRetry = false

    Backoff : _attempt = null, _subscription = null
    Backoff : _retryTimer active

    Done : _attempt = null, _subscription = null
    Done : all timers inactive

    state RetryCheck <<choice>>

    [*] --> WaitingForListen : _Call created
    WaitingForListen --> Sending : onListen / _startAttempt()

    Sending --> ReadingBody : _onResponse (non-2xx, 2xx unary, or 2xx JSON)
    Sending --> StreamingSse : _onResponse (2xx text/event-stream)
    Sending --> RetryCheck : _send error, bad MIME, or timeout

    ReadingBody --> Done : onDone 2xx (_succeed), or onCancel
    ReadingBody --> RetryCheck : onDone (non-2xx or decode err), onError, or timeout

    StreamingSse --> Done : onDone (_succeed), onError/timeout (_fail), or onCancel

    RetryCheck --> Backoff : retryable Exception and delay left
    RetryCheck --> Done : otherwise (_controller.addError and close)

    Backoff --> Sending : _retryTimer / _startAttempt()

    Sending --> Done : onCancel
    Backoff --> Done : onCancel

    Done --> [*]
```

In-state events (`onData`, `onPause`, `onResume`, and stale callbacks from
abandoned attempts) do not change the lifecycle state and are detailed in the
matrix below.

## States and Field Predicates

Pause state (`_controller.isPaused`) is orthogonal to these six phases: pausing
stops `_stallTimer` and pauses `_subscription` (after one microtask), while
`_deadlineTimer` and `_retryTimer` continue running.
[`_hasResponse`](lib/service_client.dart#L463) is a purely computed getter
(`_subscription != null`), used only in the timer callbacks to select the
`TimeoutException` message.

| State | `_attempt` | `_canRetry` | `_subscription` | Active timers | Entered by |
|---|---|---|---|---|---|
| `WaitingForListen` | `null` | `true` | `null` | none | [`_Call`](lib/service_client.dart#L437) constructor |
| `Sending` | token | `true` | `null` | `_deadlineTimer`¹, `_stallTimer`² | [`_startAttempt`](lib/service_client.dart#L465) |
| `ReadingBody` | token | `true` | non-empty bytes | `_deadlineTimer`¹, `_stallTimer`² | [`_onResponse`](lib/service_client.dart#L508) → [`_readBody`](lib/service_client.dart#L563) |
| `StreamingSse` | token | `false` | decoded SSE maps | `_deadlineTimer`¹, `_stallTimer`² | [`_onResponse`](lib/service_client.dart#L542) → [`_listen`](lib/service_client.dart#L580) |
| `Backoff` | `null` | `true` | `null` | `_retryTimer` | [`_fail`](lib/service_client.dart#L658) |
| `Done` | `null` | last value | `null` | none | [`_succeed`](lib/service_client.dart#L644), [`_fail`](lib/service_client.dart#L660), [`_cancel`](lib/service_client.dart#L633) |

- ¹ Active when `_timeout != null`; counts paused time.
- ² Active when `_stallTimeout != null` and `!_controller.isPaused` (never used
  for unary calls, where `_stallTimeout` is `null`).

## Event × State Transition Matrix

Conventions:

- `—` means the event cannot occur in that state for the current attempt.
- **→ `Backoff` / `Done`** means [`_fail`](lib/service_client.dart#L652) runs
  [`_endAttempt`](lib/service_client.dart#L670), then enters `Backoff` (arms
  `_retryTimer` with `_delays.current`) if `_canRetry`, `error is Exception`,
  `_retry.isRetryable(error)`, and `_delays.moveNext()` all hold; otherwise it
  calls `_controller.addError` + `_controller.close` (`Done`).
- In `Sending`, entering `ReadingBody` or `StreamingSse` via
  [`_listen`](lib/service_client.dart#L580) immediately transitions on to
  `Backoff` or `Done` if the response stream terminates synchronously during
  `stream.listen(...)` ([L602–L605](lib/service_client.dart#L602-L605)).

| Event | `WaitingForListen` | `Sending` | `ReadingBody` | `StreamingSse` | `Backoff` | `Done` |
|---|---|---|---|---|---|---|
| `onListen` | **→ `Sending`** [`onListen`](lib/service_client.dart#L447) → [`_startAttempt`](lib/service_client.dart#L465): binds pause/resume/cancel, inits `_delays`, mints `_attempt`, starts timers, calls `_send`. | — | — | — | — | — |
| `_send` → non-2xx response (current) | — | **→ `ReadingBody`** [`_onResponse`](lib/service_client.dart#L508) ([L510–L519](lib/service_client.dart#L510-L519)): restarts stall timer, calls [`_readBody`](lib/service_client.dart#L563) (pauses sub if paused). | — | — | — | — |
| `_send` → 2xx unary or streaming `application/json` (current) | — | **→ `ReadingBody`** [`_onResponse`](lib/service_client.dart#L508) ([L520–L541](lib/service_client.dart#L520-L541)): restarts stall timer, calls [`_readBody`](lib/service_client.dart#L563) (pauses sub if paused). | — | — | — | — |
| `_send` → 2xx streaming `text/event-stream` (current) | — | **→ `StreamingSse`** [`_onResponse`](lib/service_client.dart#L508) ([L542–L551](lib/service_client.dart#L542-L551)): restarts stall timer, `_canRetry = false`, calls [`_listen`](lib/service_client.dart#L580) on [`_decodeEvents`](lib/service_client.dart#L367). | — | — | — | — |
| `_send` → 2xx streaming other/invalid MIME (current) | — | **→ `Backoff` / `Done`** [`_onResponse`](lib/service_client.dart#L552) cancels response ([`_cancelResponse`](lib/service_client.dart#L709)), throws `ServiceException`; [`_run`](lib/service_client.dart#L680) routes to [`_fail`](lib/service_client.dart#L652). | — | — | — | — |
| `_send` → error or sync throw (current) | — | **→ `Backoff` / `Done`** [`_startAttempt`](lib/service_client.dart#L494) calls [`_fail`](lib/service_client.dart#L652) (non-`Exception` `Error` always goes to `Done`). | — | — | — | — |
| Stream `onData` (current) | — | — | **Stay `ReadingBody`** [`_listen`](lib/service_client.dart#L588): appends non-empty chunk to `BytesBuilder` ([L570–L571](lib/service_client.dart#L570-L571)), calls [`_restartStallTimer`](lib/service_client.dart#L690). Empty chunks are filtered out. | **Stay `StreamingSse`** [`_listen`](lib/service_client.dart#L588): forwards decoded `'data: '` map to `_controller.add` ([L549](lib/service_client.dart#L549)), calls [`_restartStallTimer`](lib/service_client.dart#L690). Comments/partial lines do not fire `onData`. | — | — |
| Stream `onError` (current) | — | — | **→ `Backoff` / `Done`** [`_listen`](lib/service_client.dart#L593) calls [`_fail`](lib/service_client.dart#L652). | **→ `Done` (failed)** [`_listen`](lib/service_client.dart#L593) calls [`_fail`](lib/service_client.dart#L652) (transport or [`_decodeEvents`](lib/service_client.dart#L367) decode error; `_canRetry` is `false`). | — | — |
| Stream `onDone` (current) | — | — | **→ `Done` (succeeded) or `Backoff` / `Done`** [`_listen`](lib/service_client.dart#L596) clears `_subscription`, runs callback in [`_run`](lib/service_client.dart#L680): 2xx decodes UTF-8/JSON, adds message(s), calls [`_succeed`](lib/service_client.dart#L644); non-2xx ([L518](lib/service_client.dart#L518)) or decode failure throws to [`_fail`](lib/service_client.dart#L652). | **→ `Done` (succeeded)** [`_listen`](lib/service_client.dart#L596) clears `_subscription`, runs [`_succeed`](lib/service_client.dart#L644) via [`_run`](lib/service_client.dart#L680): calls `_endAttempt()` and `_controller.close()`. | — | — |
| `_deadlineTimer` fires (`timeout`) | — | **→ `Backoff` / `Done`** [`_startAttempt`](lib/service_client.dart#L471) → [`_timeOut`](lib/service_client.dart#L665) → [`_fail`](lib/service_client.dart#L652) (`"...did not return any data"`). | **→ `Backoff` / `Done`** [`_startAttempt`](lib/service_client.dart#L471) → [`_timeOut`](lib/service_client.dart#L665) → [`_fail`](lib/service_client.dart#L652) (`"...did not complete"`). | **→ `Done` (failed)** [`_startAttempt`](lib/service_client.dart#L471) → [`_timeOut`](lib/service_client.dart#L665) → [`_fail`](lib/service_client.dart#L652) (`"...did not complete"`, `_canRetry` is `false`). | — | — |
| `_stallTimer` fires (`streamWaitTimeout`) | — | **→ `Backoff` / `Done`** [`_restartStallTimer`](lib/service_client.dart#L698) → [`_timeOut`](lib/service_client.dart#L665) → [`_fail`](lib/service_client.dart#L652) (`"...did not return any data"`). Only fires while unpaused. | **→ `Backoff` / `Done`** [`_restartStallTimer`](lib/service_client.dart#L698) → [`_timeOut`](lib/service_client.dart#L665) → [`_fail`](lib/service_client.dart#L652) (`"No data received..."`). Only fires while unpaused. | **→ `Done` (failed)** [`_restartStallTimer`](lib/service_client.dart#L698) → [`_timeOut`](lib/service_client.dart#L665) → [`_fail`](lib/service_client.dart#L652) (`"No data received..."`, `_canRetry` is `false`). Only fires while unpaused. | — | — |
| `_retryTimer` fires | — | — | — | — | **→ `Sending`** [`_fail`](lib/service_client.dart#L658) → [`_startAttempt`](lib/service_client.dart#L465): mints `_attempt`, resets `_canRetry`, starts deadline timer (and stall timer if unpaused), calls `_send`. | — |
| `onPause` | — | **Stay `Sending`** [`_pause`](lib/service_client.dart#L612): cancels `_stallTimer`; deferred microtask is a no-op (`_subscription` is `null` or already paused by [`_listen`](lib/service_client.dart#L608)). `_deadlineTimer` keeps running. | **Stay `ReadingBody`** [`_pause`](lib/service_client.dart#L612): cancels `_stallTimer`; queues microtask ([L618](lib/service_client.dart#L618)) to pause `_subscription` if still active, unpaused, and controller paused. `_deadlineTimer` keeps running. | **Stay `StreamingSse`** [`_pause`](lib/service_client.dart#L612): cancels `_stallTimer`; queues microtask ([L618](lib/service_client.dart#L618)) to pause `_subscription` if still active, unpaused, and controller paused. `_deadlineTimer` keeps running. | **Stay `Backoff`** [`_pause`](lib/service_client.dart#L612): cancels inactive `_stallTimer`; microtask no-ops (`_subscription` is `null`). `_retryTimer` keeps running; future attempts honor `_controller.isPaused`. | — |
| `onResume` | — | **Stay `Sending`** [`_resume`](lib/service_client.dart#L628): `_subscription` is `null`; calls [`_restartStallTimer`](lib/service_client.dart#L690) to start fresh stall timer. | **Stay `ReadingBody`** [`_resume`](lib/service_client.dart#L628): calls `_subscription?.resume()` and [`_restartStallTimer`](lib/service_client.dart#L690). | **Stay `StreamingSse`** [`_resume`](lib/service_client.dart#L628): calls `_subscription?.resume()` and [`_restartStallTimer`](lib/service_client.dart#L690). | **Stay `Backoff`** [`_resume`](lib/service_client.dart#L628): no-op (`_subscription` is `null`, `_attempt` is `null`). | — |
| `onCancel` | — | **→ `Done` (cancelled)** [`_cancel`](lib/service_client.dart#L633): cancels timers, clears `_attempt` via `_endAttempt()`, returns `null`. | **→ `Done` (cancelled)** [`_cancel`](lib/service_client.dart#L633): detaches `_subscription`, calls `_endAttempt()`, returns `subscription.cancel()` (propagating cancel errors to caller). | **→ `Done` (cancelled)** [`_cancel`](lib/service_client.dart#L633): detaches `_subscription`, calls `_endAttempt()`, returns `subscription.cancel()` (propagating cancel errors to caller). | **→ `Done` (cancelled)** [`_cancel`](lib/service_client.dart#L633): cancels `_retryTimer`, calls `_endAttempt()`, returns `null`. | **Stay `Done`** If listener cancels before draining close/error, [`_cancel`](lib/service_client.dart#L633) is an idempotent no-op returning `null`. |
| Stale `_send` response (`!identical`) | — | **Stay `Sending`** [`_startAttempt`](lib/service_client.dart#L491): calls [`_cancelResponse`](lib/service_client.dart#L709) with `.ignoreExceptions()`. | **Stay `ReadingBody`** [`_startAttempt`](lib/service_client.dart#L491): calls [`_cancelResponse`](lib/service_client.dart#L709) with `.ignoreExceptions()`. | **Stay `StreamingSse`** [`_startAttempt`](lib/service_client.dart#L491): calls [`_cancelResponse`](lib/service_client.dart#L709) with `.ignoreExceptions()`. | **Stay `Backoff`** [`_startAttempt`](lib/service_client.dart#L491): calls [`_cancelResponse`](lib/service_client.dart#L709) with `.ignoreExceptions()`. | **Stay `Done`** [`_startAttempt`](lib/service_client.dart#L491): calls [`_cancelResponse`](lib/service_client.dart#L709) with `.ignoreExceptions()`. |
| Stale `_send` error (`!identical`) | — | **Stay `Sending`** [`_startAttempt`](lib/service_client.dart#L497): ignores `Exception`; rethrows `Error` uncaught ([L501](lib/service_client.dart#L501)). | **Stay `ReadingBody`** [`_startAttempt`](lib/service_client.dart#L497): ignores `Exception`; rethrows `Error` uncaught ([L501](lib/service_client.dart#L501)). | **Stay `StreamingSse`** [`_startAttempt`](lib/service_client.dart#L497): ignores `Exception`; rethrows `Error` uncaught ([L501](lib/service_client.dart#L501)). | **Stay `Backoff`** [`_startAttempt`](lib/service_client.dart#L497): ignores `Exception`; rethrows `Error` uncaught ([L501](lib/service_client.dart#L501)). | **Stay `Done`** [`_startAttempt`](lib/service_client.dart#L497): ignores `Exception`; rethrows `Error` uncaught ([L501](lib/service_client.dart#L501)). |
| Stale stream callback (`isOver()`) | — | **Stay `Sending`** [`_listen`](lib/service_client.dart#L589)/[L594](lib/service_client.dart#L594)/[L597](lib/service_client.dart#L597): returns immediately. | **Stay `ReadingBody`** [`_listen`](lib/service_client.dart#L589)/[L594](lib/service_client.dart#L594)/[L597](lib/service_client.dart#L597): returns immediately. | **Stay `StreamingSse`** [`_listen`](lib/service_client.dart#L589)/[L594](lib/service_client.dart#L594)/[L597](lib/service_client.dart#L597): returns immediately. | **Stay `Backoff`** [`_listen`](lib/service_client.dart#L589)/[L594](lib/service_client.dart#L594)/[L597](lib/service_client.dart#L597): returns immediately. | **Stay `Done`** [`_listen`](lib/service_client.dart#L589)/[L594](lib/service_client.dart#L594)/[L597](lib/service_client.dart#L597): returns immediately. |

### Shared Transition Helpers

- [`_endAttempt`](lib/service_client.dart#L670-L676): clears `_attempt = null`,
  cancels `_deadlineTimer` and `_stallTimer`, cancels `_subscription` with
  [`ignoreExceptions`](lib/service_client.dart#L716-L720) (swallowing
  `Exception`s while letting `Error`s surface), and sets `_subscription = null`.
  By contrast, [`_cancel`](lib/service_client.dart#L633-L641) detaches
  `_subscription` first and returns `subscription?.cancel()` directly so
  explicit cancellation errors reach the caller.
- [`_restartStallTimer`](lib/service_client.dart#L690-L705): returns early if
  `_stallTimeout == null || _attempt == null || _controller.isPaused`;
  otherwise cancels any running `_stallTimer` and arms a fresh timer.
- [`_run`](lib/service_client.dart#L680-L686): wraps synchronous work
  ([`_onResponse`](lib/service_client.dart#L487) and stream `onDone` at
  [L599](lib/service_client.dart#L599)) in `try`/`catch` and routes any thrown
  object to [`_fail`](lib/service_client.dart#L652).

## Three Subtle Mechanisms in `_Call`

### 1. `_attempt` Identity Guard

Because `http.Client.send` cannot be aborted when an attempt times out or is
cancelled ([L480–L482](lib/service_client.dart#L480-L482)), an abandoned
attempt's `_send` future or response stream may still deliver callbacks later,
including after a retry has already started a *new* attempt.

[`_startAttempt`](lib/service_client.dart#L466) therefore assigns a fresh
`Object()` token (`final attempt = _attempt = Object()`) and captures `attempt`
in both the `_send` callbacks ([L486](lib/service_client.dart#L486),
[L495](lib/service_client.dart#L495)) and
[`_listen`](lib/service_client.dart#L585-L586)'s `isOver()` closure
(`!identical(attempt, _attempt)`).
[`_endAttempt`](lib/service_client.dart#L671) sets `_attempt = null`. Using
object identity instead of a boolean ensures a late callback from attempt 1
cannot interfere with attempt 2:

- A late `_send` response is drained immediately via
  `_cancelResponse(response).ignoreExceptions()`
  ([L491](lib/service_client.dart#L491)) to release the HTTP connection.
- A late `_send` `Exception` is ignored, while a non-`Exception` `Error` is
  rethrown uncaught via `Error.throwWithStackTrace`
  ([L497–L502](lib/service_client.dart#L497-L502)) so programming bugs are not
  hidden.
- Late stream callbacks check `isOver()` and return without mutating state
  ([L589](lib/service_client.dart#L589), [L594](lib/service_client.dart#L594),
  [L597](lib/service_client.dart#L597)).

### 2. Sync-Done `isOver()` Check in `_listen`

In [`_listen`](lib/service_client.dart#L580-L610), `stream.listen(...)` runs
*before* `_subscription` is assigned
([L587–L607](lib/service_client.dart#L587-L607)). If `stream` delivers
`onDone` or `onError` synchronously inside `listen()`, the callback runs
[`_succeed`](lib/service_client.dart#L644) or
[`_fail`](lib/service_client.dart#L652) →
[`_endAttempt`](lib/service_client.dart#L670), clearing `_attempt` before
`stream.listen(...)` returns.

Checking `if (isOver())` right after `stream.listen(...)`
([L602–L609](lib/service_client.dart#L602-L609)) catches that case: `_listen`
cancels the returned subscription (`.ignoreExceptions()`) instead of storing a
dead subscription on an already-ended attempt. Otherwise it saves
`_subscription` and immediately pauses it if `_controller.isPaused` is already
`true` ([L608](lib/service_client.dart#L608)) — for example, when headers
arrive while the caller is paused.

### 3. One-Microtask Deferred `_pause`

When the caller pauses the stream, [`_pause`](lib/service_client.dart#L612-L626)
cancels `_stallTimer` immediately ([L613](lib/service_client.dart#L613)) so
paused time never counts against `streamWaitTimeout`, but defers
`subscription.pause()` by one microtask via `scheduleMicrotask`
([L618–L625](lib/service_client.dart#L618-L625)).

This avoids a false `timeout` on an already-finished stream: if the listener
calls `pause()` inside `onData` on the final SSE event while the upstream
`onDone` is already queued behind it, pausing synchronously would hold `onDone`
back and leave `_deadlineTimer` ticking while paused. Deferring by one
microtask lets `onDone` run first, call
[`_succeed`](lib/service_client.dart#L644), and cancel `_deadlineTimer`.

When the microtask executes, three guards
([L620–L622](lib/service_client.dart#L620-L622)) handle intervening events:

- `subscription != null`: skips if the attempt ended (`_succeed`, `_fail`, or
  `_cancel`) before the microtask ran.
- `!subscription.isPaused`: avoids double-pausing (Dart's
  `StreamSubscription.pause` is reference-counted) if `_listen`
  ([L608](lib/service_client.dart#L608)) or an earlier pause microtask already
  paused it.
- `_controller.isPaused`: skips if [`_resume`](lib/service_client.dart#L628)
  ran before the microtask fired.
