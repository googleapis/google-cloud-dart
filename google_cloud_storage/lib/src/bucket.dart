import 'package:google_cloud_protobuf/protobuf.dart';

class Bucket implements JsonEncodable {
  final String name;

  Bucket({required this.name});

  factory Bucket.fromJson(Map<String, dynamic> json) {
    return Bucket(name: json['name'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  @override
  String toString() {
    return 'Bucket(name: $name)';
  }
}
