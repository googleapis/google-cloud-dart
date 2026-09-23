// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:webcrypto/webcrypto.dart';

import 'wycheproof_data.dart';

Uint8List _hexToBytes(String hexString) {
  if (hexString.isEmpty) return Uint8List(0);
  return Uint8List.fromList(hex.decode(hexString));
}

Uint8List _base64UrlDecodeUnpadded(String s) {
  if (s.contains('=')) {
    throw const FormatException('Padding is not allowed in JWS.');
  }
  // Dart's base64Url.decode sometimes requires padding depending on length.
  final pad = s.length % 4;
  final padded = pad == 0 ? s : s + '=' * (4 - pad);
  return base64Url.decode(padded);
}

/// Simple JWS RS256 verification logic modelled after #B12JV / #FBFF8 requirements
/// to exercise `package:webcrypto` and strict JWS specs.
Future<bool> _verifyJwsRs256(String jws, Map<String, dynamic> jwkData) async {
  final parts = jws.split('.');
  if (parts.length != 3) {
    return false;
  }

  try {
    final headerBytes = _base64UrlDecodeUnpadded(parts[0]);
    final headerJson = json.decode(utf8.decode(headerBytes));
    if (headerJson is! Map<String, dynamic>) return false;

    // Strict RS256 enforcement (Algorithm Confusion & "none" rejection)
    final alg = headerJson['alg'];
    if (alg != 'RS256') return false;

    // Reject unknown critical headers per RFC 7515 §4.1.11
    final crit = headerJson['crit'];
    if (crit != null) {
      if (crit is! List) return false;
      if (crit.isNotEmpty) {
        // We do not support any extensions in this simplified verifier.
        // Therefore, any "crit" parameter causes rejection.
        return false;
      }
    }

    // ignore: unused_local_variable
    final payloadBytes = _base64UrlDecodeUnpadded(parts[1]);
    final signatureBytes = _base64UrlDecodeUnpadded(parts[2]);

    final signedBytes = ascii.encode('${parts[0]}.${parts[1]}');

    final publicKey = await RsassaPkcs1V15PublicKey.importJsonWebKey(
      jwkData,
      Hash.sha256,
    );

    return await publicKey.verifyBytes(signatureBytes, signedBytes);
  } on Exception {
    return false;
  }
}

void main() {
  _testRsaSignatures();
  _testJws();
}

void _testRsaSignatures() {
  const rsaFiles = {
    'rsa_signature_2048_sha256_test.json': Hash.sha256,
    'rsa_signature_3072_sha256_test.json': Hash.sha256,
    'rsa_signature_4096_sha256_test.json': Hash.sha256,
  };

  for (final entry in rsaFiles.entries) {
    final filename = entry.key;
    final hashAlgorithm = entry.value;

    group('Wycheproof $filename', () {
      final base64String = wycheproofVectorsBase64[filename];
      if (base64String == null) {
        fail('Test vector $filename not found.');
      }
      final jsonString = utf8.decode(base64.decode(base64String));
      final jsonVector = json.decode(jsonString) as Map<String, dynamic>;
      final testGroups = (jsonVector['testGroups'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (final groupData in testGroups) {
        final sha = groupData['sha'];
        if (sha != 'SHA-256') continue;

        final keySize = groupData['keySize'] as int;
        final publicKeyDerStr = groupData['publicKeyDer'] as String;
        final tests = (groupData['tests'] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        group('keySize: $keySize', () {
          for (final testCase in tests) {
            final tcId = testCase['tcId'] as int;
            final comment = testCase['comment'] as String;
            final result = testCase['result'] as String;
            final msgHex = testCase['msg'] as String;
            final sigHex = testCase['sig'] as String;

            test('tcId $tcId: $comment', () async {
              final msgBytes = _hexToBytes(msgHex);
              final sigBytes = _hexToBytes(sigHex);
              final spkiBytes = _hexToBytes(publicKeyDerStr);

              final publicKey = await RsassaPkcs1V15PublicKey.importSpkiKey(
                spkiBytes,
                hashAlgorithm,
              );

              final isValid = await publicKey.verifyBytes(sigBytes, msgBytes);

              if (result == 'valid' || result == 'acceptable') {
                expect(isValid, isTrue, reason: 'Expected valid signature');
              } else if (result == 'invalid') {
                expect(isValid, isFalse, reason: 'Expected invalid signature');
              } else {
                fail('Unknown test result flag: $result');
              }
            });
          }
        });
      }
    });
  }
}

void _testJws() {
  group('Wycheproof json_web_signature_test.json', () {
    final base64String =
        wycheproofVectorsBase64['json_web_signature_test.json'];
    final jsonString = utf8.decode(base64.decode(base64String!));
    final jsonVector = json.decode(jsonString) as Map<String, dynamic>;
    final testGroups = (jsonVector['testGroups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    for (final groupData in testGroups) {
      final privateJwk = groupData['private'] as Map<String, dynamic>;
      // For this test, we only want to evaluate RS256 JWK scenarios contextually
      // However, algorithm confusion tests might use HS256 with an RSA public key.
      // Wycheproof tests include the correct key in 'private' for the JWS being tested.
      // We are writing an RS256 specific endpoint, so we supply the test's key
      // but stripped down to a public RS256 JWK, no matter what it originally was,
      // EXCEPT some test groups might not be RSA.
      // Let's filter to RSA test groups. The test vectors for alg confusion
      // where an RSA key is checked with HS256 will have kty: "RSA".
      if (privateJwk['kty'] != 'RSA') continue;

      // Extract the public RSA JWK only
      final publicJwk = <String, dynamic>{
        'kty': 'RSA',
        if (privateJwk.containsKey('alg')) 'alg': privateJwk['alg'],
        if (privateJwk.containsKey('use')) 'use': privateJwk['use'],
        if (privateJwk.containsKey('kid')) 'kid': privateJwk['kid'],
        'n': privateJwk['n'],
        'e': privateJwk['e'],
      };

      final tests = (groupData['tests'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (final testCase in tests) {
        final tcId = testCase['tcId'] as int;
        final comment = testCase['comment'] as String;
        final result = testCase['result'] as String;
        final jwsStr = testCase['jws'] as String;

        test('tcId $tcId: $comment', () async {
          final isValid = await _verifyJwsRs256(jwsStr, publicJwk);

          if (result == 'valid' || result == 'acceptable') {
            expect(
              isValid,
              isTrue,
              reason: 'Expected valid signature verification',
            );
          } else if (result == 'invalid') {
            expect(
              isValid,
              isFalse,
              reason: 'Expected invalid signature verification',
            );
          } else {
            fail('Unknown test result flag: $result');
          }
        });
      }
    }
  });
}
