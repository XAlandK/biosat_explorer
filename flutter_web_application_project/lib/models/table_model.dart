import 'package:biosat_explorer/utils/extensions.dart';

class TableModel {
  final String? caption;
  final List<List<String>>? headers;
  final List<List<String>>? rows;
  final String? section;

  TableModel({
    this.caption,
    this.headers,
    this.rows,
    this.section,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      caption: json['caption'],
      headers: json['headers'] != null
          ? List<List<String>>.from(
              json['headers'].map(
                (x) => List<String>.from(x.map((y) => y.toString())),
              ),
            )
          : null,
      rows: json['rows'] != null
          ? List<List<String>>.from(
              json['rows'].map(
                (x) => List<String>.from(x.map((y) => y.toString())),
              ),
            )
          : null,
      section: json['section'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'headers': headers,
      'rows': rows,
      'section': section,
    };
  }

  bool get hasCaption => caption.isNotNullAndNotEmpty;
  bool get hasHeaders => headers.isListNotNullAndNotEmpty;
  bool get hasRows => rows.isListNotNullAndNotEmpty;
  bool get hasSection => section.isNotNullAndNotEmpty;
}