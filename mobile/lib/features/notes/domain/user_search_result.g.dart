// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSearchResult _$UserSearchResultFromJson(Map<String, dynamic> json) =>
    _UserSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImage: json['profileImage'] as String?,
    );

Map<String, dynamic> _$UserSearchResultToJson(_UserSearchResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'profileImage': instance.profileImage,
    };
