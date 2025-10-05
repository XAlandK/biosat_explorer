import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biosat_explorer/models/body_content_model.dart';
import 'package:biosat_explorer/models/research_model.dart';
import 'package:biosat_explorer/utils/extensions.dart';

class SupabaseSingleResearchProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  ResearchModel? _research;
  bool _isLoading = false;
  String? _error;

  ResearchModel? get getResearch => _research;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasResearch => getResearch.isNotNull;

  void setResearch(ResearchModel research) {
    _research = research;
    notifyListeners();
    getResearch;
    return;
  }

  Future<void> fetch_table_body_content() async {
    if (!hasResearch) {
      return;
    }
    if (getResearch!.hasBodyContent) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await (() {
        final PostgrestFilterBuilder<PostgrestList> base = supabase
            .from('body_content')
            .select()
            .eq('research_article_id', getResearch!.id)
            .neq('heading', '')
            .neq('content', '');

        return base;
      })();

      // Normalize response
      final List<BodyContentModel>? fetchedBodyContent = response
          .cast<Map<String, dynamic>>()
          .map((e) => BodyContentModel.fromJson(e))
          .toList();

      if (fetchedBodyContent.isNotNullAndNotEmpty) {
        _research = getResearch!.copyWith(
          bodyContent: fetchedBodyContent,
        );
      }
        } catch (e) {
      _research = null;
      _error = 'Failed to load from Supabase: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
