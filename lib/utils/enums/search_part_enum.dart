enum SearchPartEnum {
  title,
  keywords,
  abstract,
  author;

  static List<String> get getNames => values.map((e) => e.name).toList();
}

enum SearchSortPartEnum {
  newest,
  oldest;

  static List<String> get getNames => values.map((e) => e.name).toList();

  bool get isNewest => this == newest;
}
