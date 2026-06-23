// lib/core/extensions/list_extensions.dart

extension ListExtension<T> on List<T> {
  void addIf(bool condition, T element) {
    if (condition) add(element);
  }
}