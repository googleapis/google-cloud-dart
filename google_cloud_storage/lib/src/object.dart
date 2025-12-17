
class StorageObject {
  final String bucket;
  final String name;
  final String? id;
  final String? kind;
  final String? contentType;
  final String? timeCreated;
  final String? updated;
  final String? size;
  final String? md5Hash;
  final String? mediaLink;

  StorageObject({
    required this.bucket,
    required this.name,
    this.id,
    this.kind,
    this.contentType,
    this.timeCreated,
    this.updated,
    this.size,
    this.md5Hash,
    this.mediaLink,
  });

  factory StorageObject.fromJson(Map<String, dynamic> json) {
    return StorageObject(
      bucket: json['bucket'] as String,
      name: json['name'] as String,
      id: json['id'] as String?,
      kind: json['kind'] as String?,
      contentType: json['contentType'] as String?,
      timeCreated: json['timeCreated'] as String?,
      updated: json['updated'] as String?,
      size: json['size'] as String?,
      md5Hash: json['md5Hash'] as String?,
      mediaLink: json['mediaLink'] as String?,
    );
  }
}

class ListObjectsResponse {
  final List<StorageObject> items;
  final String? nextPageToken;

  ListObjectsResponse({required this.items, this.nextPageToken});

  factory ListObjectsResponse.fromJson(Map<String, dynamic> json) {
    return ListObjectsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => StorageObject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'] as String?,
    );
  }
}
