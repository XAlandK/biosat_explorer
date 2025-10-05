extension ObjectExtensions on Object? {
  bool get isNotNull => this != null;
  bool get isNotNullAndNotEmpty {
    if (this == null) return false;
    if (this is String) return (this as String).isNotEmpty;
    if (this is List) return (this as List).isNotEmpty;
    if (this is Map) return (this as Map).isNotEmpty;
    if (this is Set) return (this as Set).isNotEmpty;
    return true;
  }
}

extension ListExtensions on List? {
  bool get isListNotNullAndNotEmpty {
    return this != null && this!.isNotEmpty;
  }
}

extension StringExtensions on String? {
  bool get isNotNullAndNotEmpty {
    return this != null && this!.isNotEmpty;
  }
}
