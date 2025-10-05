import 'package:biosat_explorer/utils/extensions.dart';

class ReferenceModel {
  final String? id;
  final String? citation;

  ReferenceModel({this.id, this.citation});

  factory ReferenceModel.fromJson(Map<String, dynamic> json) {
    return ReferenceModel(id: json['id'], citation: json['citation']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'citation': citation};
  }

  bool get hasId => id.isNotNullAndNotEmpty;
  bool get hasCitation => citation.isNotNullAndNotEmpty;
}
