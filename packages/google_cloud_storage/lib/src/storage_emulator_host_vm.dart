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

String? _getPosixEnvironmentVariable(String name) {
  final getenv = DynamicLibrary.process()
      .lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>)
      >('getenv');
  return using((arena) {
    final namePtr = name.toNativeUtf8(allocator: arena);
    final valuePtr = getenv(namePtr);
    if (valuePtr == nullptr) {
      return null;
    }
    return valuePtr.toDartString();
  });
}

String? _getWindowsEnvironmentVariable(String name) {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final getEnvironmentVariableW = kernel32
      .lookupFunction<
        Int32 Function(Pointer<Utf16>, Pointer<Utf16>, Int32),
        int Function(Pointer<Utf16>, Pointer<Utf16>, int)
      >('GetEnvironmentVariableW');

  return using((arena) {
    final namePtr = name.toNativeUtf16(allocator: arena);
    // First call to determine size
    final size = getEnvironmentVariableW(namePtr, nullptr, 0);
    if (size == 0) {
      return null; // Error or empty.
    }

    final buffer = arena<Uint16>(size).cast<Utf16>();
    final finalSize = getEnvironmentVariableW(namePtr, buffer, size);
    if (finalSize == 0 || finalSize > size) {
      return null; // Error or race condition where variable grew?
    }
    return buffer.toDartString();
  });
}

String? _getEnvironmentVariable(String name) {
  if (Platform.isWindows) {
    return _getWindowsEnvironmentVariable(name);
  } else {
    return _getPosixEnvironmentVariable(name);
  }
}

String? getStorageEmulatorHost() {
  final host = _getEnvironmentVariable('STORAGE_EMULATOR_HOST');
  if (host?.isEmpty ?? true) return null;
  return host;
}
