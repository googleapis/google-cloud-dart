// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

final _getenv = DynamicLibrary.process()
    .lookupFunction<
      Pointer<Utf8> Function(Pointer<Utf8>),
      Pointer<Utf8> Function(Pointer<Utf8>)
    >('getenv');

final _getEnvironmentVariableW = DynamicLibrary.open('kernel32.dll')
    .lookupFunction<
      Int32 Function(Pointer<Utf16>, Pointer<Utf16>, Int32),
      int Function(Pointer<Utf16>, Pointer<Utf16>, int)
    >('GetEnvironmentVariableW');

String? _posixEnvironmentVariable(String name) => using((arena) {
  final namePtr = name.toNativeUtf8(allocator: arena);
  final valuePtr = _getenv(namePtr);
  if (valuePtr == nullptr) {
    return null;
  }
  return valuePtr.toDartString();
});

String? _windowsEnvironmentVariable(String name) => using((arena) {
  final namePtr = name.toNativeUtf16(allocator: arena);
  // First call to determine size
  final size = _getEnvironmentVariableW(namePtr, nullptr, 0);
  if (size == 0) {
    return null; // Error or empty.
  }

  final buffer = arena<Uint16>(size).cast<Utf16>();
  final finalSize = _getEnvironmentVariableW(namePtr, buffer, size);
  if (finalSize == 0 || finalSize > size) {
    return null; // Error or race condition where variable grew?
  }
  return buffer.toDartString();
});

String? _environmentVariable(String name) {
  if (Platform.isWindows) {
    return _windowsEnvironmentVariable(name);
  } else {
    return _posixEnvironmentVariable(name);
  }
}

/// The host and port of the Google Cloud Pub/Sub emulator, if set.
///
/// Reads the `PUBSUB_EMULATOR_HOST` environment variable directly using native
/// code. [Platform.environment] is not used because it is cached and immutable
/// and the emulator configuration might not be available until the application
/// is launched.
@internal
String? get pubsubEmulatorHost {
  final host = _environmentVariable('PUBSUB_EMULATOR_HOST');
  if (host?.isEmpty ?? true) return null;
  return host;
}

/// The project ID inferred from the environment.
///
/// Reads the `GOOGLE_CLOUD_PROJECT` environment variable directly using native
/// code.
@internal
String? get projectFromEnvironment {
  final project = _environmentVariable('GOOGLE_CLOUD_PROJECT');
  if (project?.isEmpty ?? true) return null;
  return project;
}
