/// Splits [items] into consecutive chunks of at most [size] elements.
List<List<T>> chunkList<T>(List<T> items, int size) {
  if (items.isEmpty || size <= 0) return [];
  final chunks = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    final end = i + size < items.length ? i + size : items.length;
    chunks.add(items.sublist(i, end));
  }
  return chunks;
}
