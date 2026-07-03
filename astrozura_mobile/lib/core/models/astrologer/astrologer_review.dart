class AstrologerReview {
  final String userName;
  final double rating;
  final String comment;
  final String? image;

  AstrologerReview({
    required this.userName,
    required this.rating,
    required this.comment,
    this.image,
  });
}