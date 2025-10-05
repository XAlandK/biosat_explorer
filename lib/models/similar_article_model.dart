import 'package:biosat_explorer/utils/extensions.dart';

class SimilarArticleModel {
  final String? title;
  final String? url;
  final String? journal;

  SimilarArticleModel({
    this.title,
    this.url,
    this.journal,
  });

  factory SimilarArticleModel.fromJson(Map<String, dynamic> json) {
    return SimilarArticleModel(
      title: json['title'],
      url: json['url'],
      journal: json['journal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'journal': journal,
    };
  }

  bool get hasTitle => title.isNotNullAndNotEmpty;
  bool get hasUrl => url.isNotNullAndNotEmpty;
  bool get hasJournal => journal.isNotNullAndNotEmpty;
}