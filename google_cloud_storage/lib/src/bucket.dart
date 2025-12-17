
class Bucket {
  final String id;
  final String name;
  final String? kind;
  final String? location;
  final String? storageClass;

  Bucket({
    required this.id,
    required this.name,
    this.kind,
    this.location,
    this.storageClass,
  });

  factory Bucket.fromJson(Map<String, dynamic> json) {
    return Bucket(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String?,
      location: json['location'] as String?,
      storageClass: json['storageClass'] as String?,
    );
  }
}

class ListBucketsResponse {
  final List<Bucket> items;
  final String? nextPageToken;

  ListBucketsResponse({required this.items, this.nextPageToken});

  factory ListBucketsResponse.fromJson(Map<String, dynamic> json) {
    return ListBucketsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Bucket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'] as String?,
    );
  }
}
