import 'package:flutter/foundation.dart';

import 'package:biosat_explorer/models/table_model.dart';
import 'package:biosat_explorer/utils/extensions.dart';

import 'body_content_model.dart';
import 'reference_model.dart';
import 'similar_article_model.dart';

class ResearchModel {
  final int id;
  final String? title;
  final String? authors;
  final String? keywords;
  final String? publishedAt;
  final String? publishedAtFormatted;
  final String? doi;
  final List<BodyContentModel>? bodyContent;
  final List<ReferenceModel>? references;
  final String? pmid;
  final String? pmcId;
  final List<TableModel>? tables;
  final String? sourceURL;
  final List<SimilarArticleModel>? similarArticles;
  final List<SimilarArticleModel>? citedByArticles;
  final double? score;

  ResearchModel({
    required this.id,
    this.title,
    this.authors,
    this.keywords,
    this.publishedAt,
    this.publishedAtFormatted,
    this.doi,
    this.bodyContent,
    this.references,
    this.pmid,
    this.pmcId,
    this.tables,
    this.sourceURL,
    this.similarArticles,
    this.citedByArticles,
    this.score,
  });

  List<String>? get getKeywords => keywords?.replaceAll(' ', '').split(',');

  factory ResearchModel.fromJson(Map<String, dynamic> json) {
    var json2 = json['publishedat'];
    var json3 = json['publishedat_formatted'];
    // print('publishedat: $json2');
    // print('publishedat_formatted: $json3');
    return ResearchModel(
      id: json['id'] ?? 0,
      title: json['title'],
      authors: json['authors'],
      keywords: json['keywords'],
      publishedAt: json2,
      publishedAtFormatted: json3,
      doi: json['doi'],
      score: json['score'],
      bodyContent: json['bodyContent'] != null
          ? List<BodyContentModel>.from(
              json['bodyContent'].map((x) => BodyContentModel.fromJson(x)),
            )
          : null,
      references: json['references'] != null
          ? List<ReferenceModel>.from(
              json['references'].map((x) => ReferenceModel.fromJson(x)),
            )
          : null,
      pmid: json['pmid'],
      pmcId: json['pmcId'],
      tables: json['tables'] != null
          ? List<TableModel>.from(
              json['tables'].map((x) => TableModel.fromJson(x)),
            )
          : null,
      sourceURL: json['source_url'],
      similarArticles: json['similarArticles'] != null
          ? List<SimilarArticleModel>.from(
              json['similarArticles'].map(
                (x) => SimilarArticleModel.fromJson(x),
              ),
            )
          : null,
      citedByArticles: json['citedByArticles'] != null
          ? List<SimilarArticleModel>.from(
              json['citedByArticles'].map(
                (x) => SimilarArticleModel.fromJson(x),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'keywords': keywords,
      'publishedat': publishedAt,
      'doi': doi,
      'bodyContent': bodyContent?.map((x) => x.toJson()).toList(),
      'references': references?.map((x) => x.toJson()).toList(),
      'pmid': pmid,
      'pmcId': pmcId,
      'tables': tables?.map((x) => x.toJson()).toList(),
      'sourceURL': sourceURL,
      'similarArticles': similarArticles?.map((x) => x.toJson()).toList(),
      'citedByArticles': citedByArticles?.map((x) => x.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJsonToAI() => <String, dynamic>{
    if (hasSourceURL) 'sourceURL': sourceURL,
    if (hasTitle) 'title': title,
    if (hasKeywords) 'keywords': getKeywords,
    if (hasPublishedAt) 'publishedat': publishedAt,
  };

  static bool check = true;
  Map<String, dynamic>? toJsonKeywords() {
    void p(str) {
      if (check) {
        // print("keywords ${counter++}:" + str);
      }
    }

    List<String>? getKeywords() {
      if (!hasBodyContent) {
        return null;
      }
      for (BodyContentModel bContent in bodyContent!) {
        if (bContent.heading != null && bContent.heading!.isEmpty) {
          if (bContent.hasContent &&
              bContent.content!.startsWith('Keywords:')) {
            String keywords = bContent.content!;
            p(keywords);
            keywords = keywords.split(':').last;
            p(keywords);
            keywords = keywords.replaceAll(' ', '');
            p(keywords);
            List<String> keywordsList = keywords.split(',');
            p("list:: $keywordsList");
            return keywordsList;
          }
        }
      }
      return null;
    }

    try {
      List<String>? keywords = getKeywords();
      if (keywords == null) return null;
      return {
        'title': title,
        'doi': doi,
        if (hasBodyContent) 'keywords': keywords,
        'pmid': pmid,
        'pmcId': pmcId,
        'sourceURL': sourceURL,
      };
    } finally {
      check = false;
    }
  }

  bool get hasTitle => title.isNotNullAndNotEmpty;
  bool get hasAuthors => authors.isNotNullAndNotEmpty;
  bool get hasKeywords => keywords.isNotNullAndNotEmpty;
  bool get hasPublishedAt => publishedAt.isNotNullAndNotEmpty;
  bool get hasPublishedAtFormatted => publishedAtFormatted.isNotNullAndNotEmpty;
  bool get hasDoi => doi.isNotNullAndNotEmpty;
  bool get hasBodyContent => bodyContent.isListNotNullAndNotEmpty;
  bool get hasReferences => references.isListNotNullAndNotEmpty;
  bool get hasPmid => pmid.isNotNullAndNotEmpty;
  bool get hasPmcId => pmcId.isNotNullAndNotEmpty;
  bool get hasTables => tables.isListNotNullAndNotEmpty;
  bool get hasSourceURL => sourceURL.isNotNullAndNotEmpty;
  bool get hasSimilarArticles => similarArticles.isListNotNullAndNotEmpty;
  bool get hasCitedByArticles => citedByArticles.isListNotNullAndNotEmpty;
  bool get hasScore => score.isNotNullAndNotEmpty;

  ResearchModel copyWith({
    int? id,
    String? title,
    String? authors,
    String? keywords,
    String? publishedAt,
    String? publishedAtFormatted,
    String? doi,
    List<BodyContentModel>? bodyContent,
    List<ReferenceModel>? references,
    String? pmid,
    String? pmcId,
    List<TableModel>? tables,
    String? sourceURL,
    List<SimilarArticleModel>? similarArticles,
    List<SimilarArticleModel>? citedByArticles,
  }) {
    return ResearchModel(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      keywords: keywords ?? this.keywords,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedAtFormatted: publishedAtFormatted ?? this.publishedAtFormatted,
      doi: doi ?? this.doi,
      bodyContent: bodyContent ?? this.bodyContent,
      references: references ?? this.references,
      pmid: pmid ?? this.pmid,
      pmcId: pmcId ?? this.pmcId,
      tables: tables ?? this.tables,
      sourceURL: sourceURL ?? this.sourceURL,
      similarArticles: similarArticles ?? this.similarArticles,
      citedByArticles: citedByArticles ?? this.citedByArticles,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ResearchModel &&
        other.id == id &&
        other.title == title &&
        other.authors == authors &&
        other.keywords == keywords &&
        other.publishedAt == publishedAt &&
        other.publishedAtFormatted == publishedAtFormatted &&
        other.doi == doi &&
        listEquals(other.bodyContent, bodyContent) &&
        listEquals(other.references, references) &&
        other.pmid == pmid &&
        other.pmcId == pmcId &&
        listEquals(other.tables, tables) &&
        other.sourceURL == sourceURL &&
        listEquals(other.similarArticles, similarArticles) &&
        listEquals(other.citedByArticles, citedByArticles);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        authors.hashCode ^
        keywords.hashCode ^
        publishedAt.hashCode ^
        publishedAtFormatted.hashCode ^
        doi.hashCode ^
        bodyContent.hashCode ^
        references.hashCode ^
        pmid.hashCode ^
        pmcId.hashCode ^
        tables.hashCode ^
        sourceURL.hashCode ^
        similarArticles.hashCode ^
        citedByArticles.hashCode;
  }
}
