library google_cloud_storage;

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'bucket.dart';
import 'object.dart';
import 'utils.dart';

class StorageClient {
  final http.Client _client;
  final String _basePath = 'https://storage.googleapis.com/storage/v1/';
  final String _uploadPath = 'https://storage.googleapis.com/upload/storage/v1/';

  StorageClient(this._client);

  Future<Bucket> getBucket(String bucketName) async {
    final response = await retryRequest(() => 
      _client.get(Uri.parse('$_basePath' + 'buckets/' + bucketName)));
    
    if (response.statusCode != 200) {
      throw http.ClientException('Failed to get bucket: ${response.statusCode} ${response.reasonPhrase}', response.request?.url);
    }
    return Bucket.fromJson(jsonDecode(response.body));
  }

  Future<ListBucketsResponse> listBuckets() async {
    final response = await retryRequest(() => 
      _client.get(Uri.parse('$_basePath' + 'buckets')));
    
    if (response.statusCode != 200) {
      throw http.ClientException('Failed to list buckets: ${response.statusCode} ${response.reasonPhrase}', response.request?.url);
    }
    return ListBucketsResponse.fromJson(jsonDecode(response.body));
  }

  Future<StorageObject> getObject(String bucketName, String objectName) async {
    final response = await retryRequest(() => 
      _client.get(Uri.parse('$_basePath' + 'b/' + bucketName + '/o/' + objectName + '?alt=json')));
    
    if (response.statusCode != 200) {
      throw http.ClientException('Failed to get object: ${response.statusCode} ${response.reasonPhrase}', response.request?.url);
    }
    return StorageObject.fromJson(jsonDecode(response.body));
  }

  Future<ListObjectsResponse> listObjects(String bucketName) async {
    final response = await retryRequest(() => 
      _client.get(Uri.parse('$_basePath' + 'b/' + bucketName + '/o')));
    
    if (response.statusCode != 200) {
      throw http.ClientException('Failed to list objects: ${response.statusCode} ${response.reasonPhrase}', response.request?.url);
    }
    return ListObjectsResponse.fromJson(jsonDecode(response.body));
  }

  Future<StorageObject> uploadObject(
    String bucketName,
    String objectName,
    Stream<List<int>> data,
    int contentLength, {
    String? contentType,
  }) async {
    // 1. Initiate resumable upload
    final initiateUri = Uri.parse(
        '$_uploadPath' + 'b/$bucketName/o?uploadType=resumable&name=$objectName');
    
    final initiateResponse = await retryRequest(() => _client.post(
      initiateUri,
      headers: {
        'X-Upload-Content-Type': contentType ?? 'application/octet-stream',
        'X-Upload-Content-Length': contentLength.toString(),
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ));

    if (initiateResponse.statusCode != 200) {
       throw http.ClientException('Failed to initiate upload: ${initiateResponse.statusCode} ${initiateResponse.reasonPhrase}', initiateResponse.request?.url);
    }

    final uploadUri = initiateResponse.headers['location'];
    if (uploadUri == null) {
       throw http.ClientException('Upload URL not found in response headers');
    }

    // 2. Upload data
    // Note: This simple implementation does not fully utilize resumable capabilities (chunking/resuming).
    // It performs a single PUT request with the stream.
    final request = http.StreamedRequest('PUT', Uri.parse(uploadUri));
    request.headers['Content-Length'] = contentLength.toString();
    if (contentType != null) {
       request.headers['Content-Type'] = contentType;
    }
    
    data.listen(request.sink.add, onDone: request.sink.close, onError: request.sink.addError);

    // We don't wrap this in the generic retryRequest because we can't easily replay the stream.
    // A robust implementation would need to buffer chunks or be able to reset the stream.
    final response = await _client.send(request);
    final responseBody = await http.Response.fromStream(response);

    if (responseBody.statusCode != 200 && responseBody.statusCode != 201) {
       throw http.ClientException('Failed to upload: ${responseBody.statusCode} ${responseBody.reasonPhrase}', Uri.parse(uploadUri));
    }
    
    return StorageObject.fromJson(jsonDecode(responseBody.body));
  }

  void close() {
    _client.close();
  }
}
