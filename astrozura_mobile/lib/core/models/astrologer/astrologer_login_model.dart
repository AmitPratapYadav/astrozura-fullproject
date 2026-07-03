class AstrologerModel {

  final int id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String specialization;

  AstrologerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.specialization,
  });

  factory AstrologerModel.fromJson(
      Map<String, dynamic> json) {

    return AstrologerModel(
      id: json['id'] ?? 0,

      name: json['name'] ?? '',

      email: json['email'] ?? '',

      phone: json['phone'] ?? '',

      profileImage:
          json['profile_image'] ?? '',

      specialization:
          json['specialization'] ??
              'Certified Senior Astrologer',
    );
  }
}