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

import 'dart:convert';
import 'dart:io';

import 'package:webcrypto/webcrypto.dart';

final canUseWebCrypto = () {
  if (!const bool.fromEnvironment('dart.library.io')) return true;
  final versionStr = Platform.version.split(' ').first;
  final parts = versionStr.split('.').map(int.tryParse).toList();
  if (parts.length >= 2 && parts[0] != null && parts[1] != null) {
    if (parts[0]! > 3) return true;
    if (parts[0]! == 3 && parts[1]! >= 13) return true;
  }
  return false;
}();

const testPrivateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC86+n/Af9C9sBo
mX1jOMG6/KNa950HCYFfc+HRuTExP3G4MWJvFnmyI6Vxt13FYbhvobgkEAsDZcX6
8an5P+/9wdR3LXRILuIEYJ5L0sb/v+K9qj35AwYRmfUVPShLikxyUhw+HeJCzDWR
gtqoYmrxrumRF4r/aLQsQFW+1w/20IdzsyGqQQcsZlnid3QBKXMnzBKc1Fo4G1Fd
/laOPK7evC4PeqHjxHOvsVmHcr7P5oZLSNW4LuXb1eINroeNldtwWmsIJnkbE8aw
JC7tbirRz2Ijiq2YCSGahN8jq4EGNHk/B5Td/7F4GgJKHAuQInvDajo8QVirZ4nH
GI3rD7v1AgMBAAECggEAAPqsO5XQeUv4YuDzVGDqtCP/K9jwzBkhj03eDHMvJFDL
jJjmBWS+M40feXKM0AJobUWDcoBnVMFQPZw7gPv+caxl7NY1nKyHt0bpGyE63XRk
vvcCEApkYW7iKxXgeOh86n46jG2CaAfFkU6lF/FVMQYhSpqL9AXxxR+sbEhMoBxE
wd8jG3hF0V6wL+C7GAHimtiQg+cCRB5yDq+MTuTJ/uaMliQ87OIPcLGo7MG6rOlB
kL1rRTOTZrDduO6FJzYStxC/Em44xSsePVXEeBCOFksqWaLFw93UAFdx6cKmjIFJ
UX69Lr5ONa+nK8R/J9Gmge0MsKzKrnn86i4pXYN2MwKBgQDhII7OrtIRTXhxy/GC
05xyuJE11UzaRRbVw3l/Y0yRrggyXzENnZ2iWncY3nNmi1uWvVo5FgYk/G1ZmUs4
o1GQ7+MdXD+gMwmksT2bWmD/7jA49viSrjHigkaq/EiRAvb9AhvNp3vdUG//jJhI
nTmkH0ZSqm7i7c9M/WuxTRJ/lwKBgQDW1EzvJWt0eo1/7qRQm9a9fnvH1tutsDqU
CEzwL0il5xYATnrbvrYtkNPFFzjYJRQDqoONVSnXPzGvWe4nsCsQrMn2xBr4vr3g
1zEhLlGZygwXaFviC5258rz3iT52ApxWjI8MbLfME5/o77YbtbO9ABxQmkNOhSYk
VriLDp5SUwKBgQDcwDcoVeZozwVm2KuGNIf5OiAxoGmOsiaVD+toTW98fiFNe2g3
SLGUzI5yFVclW0tBAYWh6oW16Mw1CornC8Zkj8WtOZKuPL2c/6tAVZw9+UrR4OKX
ujXyPPqcmWtyvmyAZXvr6eocds6L0EpXEcy+sWgckUDQRo56mRjrr36PGwKBgGDo
NagvDhDl84yBHvgJxE2Ij9eusTvhYhtCv0odWj0UR9VtkXgsyEs3qH+goRDHcQbS
VTNc9lnVdNkvzQF0M4j7GMPK5IvOpyKUj+Hy3fZssRWiCsimCslFmT5kV5uuQ826
7BBjvmk9dQYDk/dd+K1KLnuhirkR0QnVYLvBpWNnAoGAfwludSo+HzcK1zNddeMD
NaFu3d2n2CLRbGRzhZL3WrZMLAxrAm/fiJz+awVaI/4oO1PGtKbqE+Xzco+Gf3/D
OP9gIW99PMdNXeCY/3cnegSg7Va7NyeMEBju8vRPdbtUzEdoYhRbWuMJZ+FQ3/t0
Cx62UQBVeiF3/RKuqixbLV4=
-----END PRIVATE KEY-----''';

const testPublicKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvOvp/wH/QvbAaJl9YzjB
uvyjWvedBwmBX3Ph0bkxMT9xuDFibxZ5siOlcbddxWG4b6G4JBALA2XF+vGp+T/v
/cHUdy10SC7iBGCeS9LG/7/ivao9+QMGEZn1FT0oS4pMclIcPh3iQsw1kYLaqGJq
8a7pkReK/2i0LEBVvtcP9tCHc7MhqkEHLGZZ4nd0ASlzJ8wSnNRaOBtRXf5Wjjyu
3rwuD3qh48Rzr7FZh3K+z+aGS0jVuC7l29XiDa6HjZXbcFprCCZ5GxPGsCQu7W4q
0c9iI4qtmAkhmoTfI6uBBjR5PweU3f+xeBoCShwLkCJ7w2o6PEFYq2eJxxiN6w+7
9QIDAQAB
-----END PUBLIC KEY-----''';

Future<RsassaPkcs1V15PublicKey> getTestPublicKey() async {
  final match = RegExp(
    r'-----BEGIN PUBLIC KEY-----(.*?)-----END PUBLIC KEY-----',
    dotAll: true,
  ).firstMatch(testPublicKey)!;
  final bytes = base64.decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
  return await RsassaPkcs1V15PublicKey.importSpkiKey(bytes, Hash.sha256);
}
