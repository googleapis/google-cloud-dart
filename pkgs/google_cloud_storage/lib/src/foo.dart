import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'object_metadata.dart';
import 'object_metadata_json.dart';

class ChunkWriter {
  final http.Client _client;
  final Uri sessionUri;
  int _end;

  ChunkWriter(this._client, this.sessionUri, this._end);

  Future<void> write(List<int> data) async {
    _client.put(
      sessionUri,
      headers: {'Content-Range': 'bytes 0-100/1000'},
      body: data,
    );
  }
}

class ResumableUpload implements StreamSink<List<int>> {
  final http.Client _client;
  final Uri sessionUri;

  ResumableUpload(this._client, this.sessionUri);

  @override
  void add(List<int> event) {
    _client.put(
      sessionUri,
      headers: {'Content-Range': 'bytes 0-100/1000'},
      body: event,
    );
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) {
    // TODO: implement addStream
    throw UnimplementedError();
  }

  @override
  Future<dynamic> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  // TODO: implement done
  Future<dynamic> get done => throw UnimplementedError();
}

Future<void> uploadFileStream(
  http.Client client,
  Uri url,
  List<int> data,
  List<int> data2, {
  ObjectMetadata? metadata,
}) async {
  final metadataJson = metadata == null
      ? <String, Object?>{}
      : objectMetadataToJson(metadata);

  final request = http.Request('POST', url);
  request.headers['Content-Type'] = 'application/json';
  request.body = jsonEncode(metadataJson);
  request.headers['Content-Length'] = request.bodyBytes.length.toString();

  final response1 = await client.send(request);
  print(response1.headers);
  if (response1.statusCode != 200) {
    throw Exception(response1.statusCode.toString());
  }

  final location = response1.headers['location'];
  if (location == null) throw Exception('No location header');

  final response2 = await client.put(
    Uri.parse(location),
    headers: {'Content-Range': 'bytes 0-${data.length - 1}/*'},
    body: data,
  );
  print(response2.headers);
  if (response2.statusCode != 308) {
    throw Exception(response2.statusCode.toString());
  }

  final again = await client.put(
    Uri.parse(location),
    headers: {'Content-Range': 'bytes 0-${data.length - 1}/*'},
    body: data,
  );
  print(again.headers);
  if (again.statusCode != 308) {
    throw Exception(again.statusCode.toString());
  }

  final response3 = await client.put(
    Uri.parse(location),
    headers: {
      'Content-Range':
          'bytes ${data.length}-${data.length + data2.length - 1}/${data.length + data2.length}',
    },
    body: data2,
  );
  print(response3.headers);
  if (response3.statusCode != 200) {
    throw Exception(response3.statusCode.toString());
  }
}
