import 'dart:io';

void main() async {
  final protosDir = Directory('protos');
  if (!protosDir.existsSync()) {
    print('Protos directory not found! Please run fetch_protos.dart first.');
    exit(1);
  }

  print('Compiling protos...');
  final result = Process.runSync('protoc', [
    '--plugin=protoc-gen-dart=tool/protoc-gen-dart.sh',
    '--dart_out=grpc:lib/src/generated',
    '-I',
    'protos',
    'protos/google/pubsub/v1/pubsub.proto',
    'protos/google/pubsub/v1/schema.proto',
    'protos/google/protobuf/timestamp.proto',
    'protos/google/protobuf/duration.proto',
    'protos/google/protobuf/field_mask.proto',
    'protos/google/protobuf/struct.proto',
    'protos/google/protobuf/empty.proto',
  ]);

  print(result.stdout);
  print(result.stderr);

  if (result.exitCode != 0) {
    print('Failed to compile protos!');
    exit(1);
  }

  final generatedDir = Directory('lib/src/generated');
  if (generatedDir.existsSync()) {
    final files = generatedDir.listSync(recursive: true);
    for (final file in files) {
      if (file is File && file.path.endsWith('.pbjson.dart')) {
        file.deleteSync();
      }
    }
  }

  print('Successfully compiled protos!');
}
