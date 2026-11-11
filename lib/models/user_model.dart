class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String phone;
  final String? email;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.phone,
    this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'phone': phone,
      if (email != null) 'email': email,
    };
  }
}
