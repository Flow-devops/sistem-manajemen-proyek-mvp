class PhotoPost {
  final int id;
  final String username;
  final String imageUrl;
  final String caption;

  PhotoPost({
    required this.id,
    required this.username,
    required this.imageUrl,
    required this.caption,
  });

  factory PhotoPost.fromJson(Map<String, dynamic> json) {
    return PhotoPost(
      id: json['id'],
      username: json['username'],
      imageUrl: json['image_url'],
      caption: json['caption'],
    );
  }
}
