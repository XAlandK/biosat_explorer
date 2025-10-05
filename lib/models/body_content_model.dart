import 'package:biosat_explorer/utils/extensions.dart';
import 'package:biosat_explorer/models/table_model.dart';

class BodyContentModel {
  final String? heading;
  final String? content;
  final List<TableModel>? tables;

  BodyContentModel({this.heading, this.content, this.tables});

  factory BodyContentModel.fromJson(Map<String, dynamic> json) {
    return BodyContentModel(
      heading: json['heading'],
      content: json['content'],
      tables: json['tables'] != null
          ? List<TableModel>.from(
              json['tables'].map((x) => TableModel.fromJson(x)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heading': heading,
      'content': content,
      'tables': tables?.map((x) => x.toJson()).toList(),
    };
  }

  bool get hasHeading => heading.isNotNullAndNotEmpty;
  bool get hasContent => content.isNotNullAndNotEmpty;
  bool get hasTables => tables.isListNotNullAndNotEmpty;
}
