// lib/models/word_pair.dart

class WordPair {
  final String category;
  final String normal;
  final String impostor;

  const WordPair({
    required this.category,
    required this.normal,
    required this.impostor,
  });

  factory WordPair.fromJson(Map<String, dynamic> json) {
    return WordPair(
      category: json['category'] as String,
      normal: json['normal'] as String,
      impostor: json['impostor'] as String,
    );
  }
}
