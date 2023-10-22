class Meme {
  final String id;
  final String name;
  final String imageUrl;

  Meme({required this.id, required this.name, required this.imageUrl});

  factory Meme.fromJson(Map<String, dynamic> json) {
    return Meme(
      id: json['id'],
      name: json['name'],
      imageUrl: json['url'],
    );
  }
}
