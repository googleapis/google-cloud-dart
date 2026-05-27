# Package Architecture: package:google_cloud_logging

This document explains how `package:google_cloud_logging` is designed, with a
focus on how it interacts with `package:google_cloud_shelf` using Dart
[Zones](https://api.dart.dev/stable/dart-async/Zone-class.html) to correlate
logs with incoming HTTP requests.

---

## Overview

`package:google_cloud_logging` provides structured logging for Dart applications
running on Google Cloud Platform (GCP). The core of the package is the
[`StructuredLogger`](lib/src/structured_logger.dart) class, which formats log
entries into a JSON format that GCP's logging agent (`google-fluentd` or the
built-in Cloud Ops agent) can automatically parse and ingest.

While emitting [structured log payloads](https://cloud.google.com/logging/docs/structured-logging)
is straightforward, the real challenge is **Log Correlation** (associating
individual log records with the specific HTTP request that triggered them). This
is achieved using Dart `Zone` variables.

---

## How Log Correlation Works

When an HTTP request is processed in a Google Cloud environment, it usually
carries a `traceparent` header (as defined by the
[W3C Trace Context specification](https://www.w3.org/TR/trace-context/)). To
correlate application logs with the request logs, every log entry must include
special fields linking it to the trace ID.

Instead of forcing developers to manually pass a logger or request context
through every function call, this repository leverages Dart's
[Zone](https://api.dart.dev/stable/dart-async/Zone-class.html) mechanism to flow
context implicitly across asynchronous boundaries.

### The Cross-Package Interaction

The interaction spans two packages:
1. **`package:google_cloud_shelf` (The Writer):** Intercepts incoming HTTP
   requests and creates a new asynchronous context (a `Zone`) with variables.
2. **`package:google_cloud_logging` (The Reader):** Reads the variables from the
   current `Zone` when a log record is emitted and constructs the appropriate
   GCP payload.

```mermaid
%%{init: {'flowchart': {'nodeSpacing': 80, 'rankSpacing': 80, 'subGraphPadding': 30}}}%%
flowchart TD
    %% Subgraph styling
    style Client fill:#F8FAFC,stroke:#E2E8F0,stroke-width:2px
    style Shelf fill:#F0FDFA,stroke:#CCFBF1,stroke-width:2px
    style Logging fill:#FAF5FF,stroke:#E9D5FF,stroke-width:2px
    style GCP fill:#EFF6FF,stroke:#DBEAFE,stroke-width:2px

    subgraph Client["Client / GCP Load Balancer"]
        Req(["<code style='white-space: nowrap;'>curl http://... -H 'traceparent: 00-...'</code>"])
    end

    subgraph Shelf["package:google_cloud_shelf"]
        MW("cloudLoggingMiddleware")
        Zone(["Forks Zone and sets: <br><code>Zone.current['traceparent']</code> <br><code>Zone.current['google_cloud_project']</code>"])
        Handler("Request Handler <br><code>logger.info('something')</code>")

        Req --> MW
        MW -->|"1. Extracts <code>traceparent</code> header"| Zone
        Zone -->|"2. Runs handler inside Zone"| Handler
    end

    subgraph Logging["package:google_cloud_logging"]
        SL[["StructuredLogger"]]
        TraceZone("structuredTraceFromZone()")
        Stdout[("stdout <br><i>Structured JSON line</i>")]

        Handler -->|"3. Emits log record"| SL
        SL -->|"4. Resolves trace ID"| TraceZone
        TraceZone -.->|"Reads from Zone"| Zone
        TraceZone -->|"5. Injects trace & project metadata"| SL
        SL -->|"6. Outputs JSON string"| Stdout
    end

    subgraph GCP["Google Cloud Platform"]
        Agent("Cloud Ops Agent <br><i>Reads stdout</i>")
        Viewer(["Cloud Log Viewer <br><i>Correlates logs by trace ID</i>"])

        Stdout --> Agent
        Agent --> Viewer
    end

    %% Node styling classes for a premium theme
    classDef clientNode fill:#F1F5F9,stroke:#94A3B8,stroke-width:1.5px,color:#0F172A;
    classDef shelfNode fill:#F0FDFA,stroke:#0D9488,stroke-width:1.5px,color:#115E59;
    classDef loggingNode fill:#FAF5FF,stroke:#9333EA,stroke-width:1.5px,color:#581C87;
    classDef gcpNode fill:#EFF6FF,stroke:#2563EB,stroke-width:1.5px,color:#1E3A8A;

    class Req clientNode;
    class MW,Zone,Handler shelfNode;
    class SL,TraceZone,Stdout loggingNode;
    class Agent,Viewer gcpNode;
```
