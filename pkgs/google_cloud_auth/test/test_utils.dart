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

import 'package:webcrypto/webcrypto.dart';

export 'src/test_utils_web.dart'
    if (dart.library.io) 'src/test_utils_io.dart'
    show canUseWebCrypto, readEnvironment, writeTempFile;

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

Future<RsassaPkcs1V15PrivateKey> testWebCryptoPrivateKey() async {
  final match = RegExp(
    r'-----BEGIN PRIVATE KEY-----(.*?)-----END PRIVATE KEY-----',
    dotAll: true,
  ).firstMatch(testPrivateKey)!;
  final bytes = base64.decode(match.group(1)!.replaceAll(RegExp(r'\s'), ''));
  return await RsassaPkcs1V15PrivateKey.importPkcs8Key(bytes, Hash.sha256);
}

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

/// A self-signed certificate for [testPublicKey], generated with:
///
/// ```shell
/// openssl req -new -x509 -key test_private_key.pem -sha256 -days 36500 \
///   -subj "/CN=google-cloud-dart test"
/// ```
///
/// where `test_private_key.pem` contains [testPrivateKey].
const testCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIDJTCCAg2gAwIBAgIUKNxxUJgThYeQZuEMbRzQ4N0g2FwwDQYJKoZIhvcNAQEL
BQAwITEfMB0GA1UEAwwWZ29vZ2xlLWNsb3VkLWRhcnQgdGVzdDAgFw0yNjEwMDky
MzM0NDdaGA8yMTI2MDkxNTIzMzQ0N1owITEfMB0GA1UEAwwWZ29vZ2xlLWNsb3Vk
LWRhcnQgdGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALzr6f8B
/0L2wGiZfWM4wbr8o1r3nQcJgV9z4dG5MTE/cbgxYm8WebIjpXG3XcVhuG+huCQQ
CwNlxfrxqfk/7/3B1HctdEgu4gRgnkvSxv+/4r2qPfkDBhGZ9RU9KEuKTHJSHD4d
4kLMNZGC2qhiavGu6ZEXiv9otCxAVb7XD/bQh3OzIapBByxmWeJ3dAEpcyfMEpzU
WjgbUV3+Vo48rt68Lg96oePEc6+xWYdyvs/mhktI1bgu5dvV4g2uh42V23Baawgm
eRsTxrAkLu1uKtHPYiOKrZgJIZqE3yOrgQY0eT8HlN3/sXgaAkocC5Aie8NqOjxB
WKtniccYjesPu/UCAwEAAaNTMFEwHQYDVR0OBBYEFABu+8kCRG8J6cSCrfoyZhrO
bPcxMB8GA1UdIwQYMBaAFABu+8kCRG8J6cSCrfoyZhrObPcxMA8GA1UdEwEB/wQF
MAMBAf8wDQYJKoZIhvcNAQELBQADggEBAF8M0jHjmVyWO/8eezt11NcSBfPvvuYT
m7LU77efIW2g4VuZ6P99i7pQDzc2rUVT6F77u29ufJ0t9FPTvo5U4W2SNOfG56JF
eOd3iQ1RwbyM+VavPq0K0Zq7kyosR/7HfiE3nkZ7hrhVzUZU9UhqUJpuyGJKD4J0
wwHtGqGs8qA0vn7zxUh2sbqmerGdHKni02dTqgbhWTRFQHiI/nCQpCntjm4BLGyi
fWXuEbrN7ZI04p6zZRLTy+RU4+I3fu258GzJjDiQEbWDg8R8VHyg7d7vClK2P/nc
VZ72j/u6NQxS1lQ94zQCokMcTTvA96vGGWgJ1S1QYTHPkRzhtvo1zCo=
-----END CERTIFICATE-----
''';

/// Encodes [bytes] as unpadded base64url, the encoding used throughout JOSE.
String base64UrlUnpadded(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// A real certificate served by
/// https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com
const testGoogleSecureTokenCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIDHDCCAgSgAwIBAgIIFFdImQ/V0kUwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE
Awwmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMjYw
NTA0MTc0NzI3WhcNMjcwNTA0MTc0NzI3WjAxMS8wLQYDVQQDDCZzZWN1cmV0b2tl
bi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAOKOpTkKGfjHH1ny5ZJXKag63eWg9RvVlfY3SgKULip4mwM1
HuCIY0aYoXEdKdVFgS/+mPOPDfSSjcYbl1/+QTZH0mBiqatIgQGegNf5naIkF9jd
SxazYShP8cgjOkRckaFdrMvEa/mNOO5wTk6AEMbUR+V1M8auOAiqeAGOvTTgbOJl
bRB9NufzI8WbysbEPRtgqDYY9WxXcrukkacecYsaLkj0qy14DTZXt08NB+ZlYnHQ
2+qoEo33lMMm67gpBTPe3mu4L9CrZ9qDxzH7WqMz+7zGeA9FqDwyMu9UONE+Ssbs
xYN6dtw12vC1S6ueAzdGgWCOTB8njBAvkrYJ0gMCAwEAAaM4MDYwDAYDVR0TAQH/
BAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ
KoZIhvcNAQEFBQADggEBALxRVxyzG7sUYwBdUGOQ8wWt7o/1tvgAVKa9VpgzzlHb
W4irMEOCetKswJFN4KieFqfUcwsKucRiDZRm9iIrPTyI3AhH9Yu7UY7lrqkYZ//b
v1Q+oj1YqYcwHcyhuykzQIf+eq1reBWhG0GaDfxTdIeQkcYBZ5nVNICBXU2QVJLE
qjM89ncbpinVTzI7kH1uZvqMDeL7/su6GSvoi4oXokOauGcaogwbbE+HK//QMOMK
XSu2FfrwU5Vua5Mx37jQTnM5ruVJQvnNYsd9QAMfhd7cUMMYuIAW1sQMSk5/F95Q
QCCW8kDKq9yAOrfHSS2zw5pqsIc/HC/bD3cW9J0CYK8=
-----END CERTIFICATE-----
''';
