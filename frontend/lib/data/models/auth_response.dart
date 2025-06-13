import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart'; // File ini akan di-generate

@JsonSerializable()
class AuthResponse {
  final String message;
  final UserData user;
  final TokenData tokens;

  AuthResponse({required this.message, required this.user, required this.tokens});

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class UserData {
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? username;

  UserData({required this.id, required this.email, this.fullName, this.username});

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

@JsonSerializable()
class TokenData {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenData.fromJson(Map<String, dynamic> json) =>
      _$TokenDataFromJson(json);

  Map<String, dynamic> toJson() => _$TokenDataToJson(this);
}