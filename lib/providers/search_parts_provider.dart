import 'package:flutter/foundation.dart';
import 'package:biosat_explorer/utils/enums/search_part_enum.dart';
import 'package:biosat_explorer/utils/extensions.dart';

class SearchPartsProvider with ChangeNotifier {
  final List<String> _allParts = SearchPartEnum.getNames;
  final List<SearchSortPartEnum> _allPartsSorts = SearchSortPartEnum.values;

  SearchSortPartEnum? selectedSortPart;
  bool get hasSelectedSortPart => selectedSortPart.isNotNull;

  late Map<String, bool> _selectedParts;

  SearchPartsProvider() {
    _selectedParts = {
      for (String part in _allParts) part: true,
    };
  }

  List<String> get allParts => _allParts;
  List<SearchSortPartEnum> get allPartsSorts => _allPartsSorts;

  Map<String, bool> get selectedParts => _selectedParts;

  List<String> get enabledParts => _selectedParts.entries.where((e) => e.value).map((e) => e.key).toList();

  void togglePart(String part) {
    if (_selectedParts.containsKey(part)) {
      _selectedParts[part] = !_selectedParts[part]!;
      notifyListeners();
    }
  }

  void setAll(bool enabled) {
    _selectedParts.updateAll((_, __) => enabled);
    notifyListeners();
  }

  void setSortPart(final SearchSortPartEnum value) {
    selectedSortPart = value;
    notifyListeners();
  }

  /// Build SQL OR query
  String buildSqlQuery(String query) {
    final enabled = enabledParts;
    if (query.trim().isEmpty || enabled.isEmpty) return '';
    return enabled.map((field) => "$field.ilike.%$query%").join(" OR ");
  }
}
