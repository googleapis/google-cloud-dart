import 'dart:io';
import 'package:http/http.dart' as http;

const googleapisBase =
    'https://raw.githubusercontent.com/googleapis/googleapis/master';
const protobufBase =
    'https://raw.githubusercontent.com/protocolbuffers/protobuf/main/src';

final filesToFetch = {
  '$googleapisBase/google/pubsub/v1/pubsub.proto':
      'google/pubsub/v1/pubsub.proto',
  '$googleapisBase/google/pubsub/v1/schema.proto':
      'google/pubsub/v1/schema.proto',
  '$googleapisBase/google/api/annotations.proto':
      'google/api/annotations.proto',
  '$googleapisBase/google/api/client.proto': 'google/api/client.proto',
  '$googleapisBase/google/api/field_behavior.proto':
      'google/api/field_behavior.proto',
  '$googleapisBase/google/api/resource.proto': 'google/api/resource.proto',
  '$googleapisBase/google/api/http.proto': 'google/api/http.proto',
  '$googleapisBase/google/api/launch_stage.proto':
      'google/api/launch_stage.proto',
  '$protobufBase/google/protobuf/empty.proto': 'google/protobuf/empty.proto',
  '$protobufBase/google/protobuf/timestamp.proto':
      'google/protobuf/timestamp.proto',
  '$protobufBase/google/protobuf/duration.proto':
      'google/protobuf/duration.proto',
  '$protobufBase/google/protobuf/field_mask.proto':
      'google/protobuf/field_mask.proto',
  '$protobufBase/google/protobuf/struct.proto': 'google/protobuf/struct.proto',
};

Future<void> fetchFile(
  http.Client client,
  String url,
  String relativePath,
) async {
  final file = File('protos/$relativePath');
  file.parent.createSync(recursive: true);

  print('Fetching $url ...');
  final response = await client.get(Uri.parse(url));
  if (response.statusCode == 200) {
    await file.writeAsBytes(response.bodyBytes);
    return;
  }
  throw Exception('Failed to fetch $url: ${response.statusCode}');
}

void main() async {
  final protosDir = Directory('protos');
  if (protosDir.existsSync()) {
    protosDir.deleteSync(recursive: true);
  }
  protosDir.createSync();

  final client = http.Client();
  try {
    final futures = filesToFetch.entries
        .map((entry) => fetchFile(client, entry.key, entry.value))
        .toList();

    await Future.wait(futures);
    print('Successfully fetched all protos!');
  } finally {
    client.close();
  }
}
