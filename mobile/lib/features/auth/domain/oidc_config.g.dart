// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oidc_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OidcConfig _$OidcConfigFromJson(Map<String, dynamic> json) => _OidcConfig(
  enabled: json['enabled'] as bool? ?? false,
  providerName: json['providerName'] as String?,
  issuerUrl: json['issuerUrl'] as String?,
  clientId: json['clientId'] as String?,
  disableInternalAuth: json['disableInternalAuth'] as bool? ?? false,
);

Map<String, dynamic> _$OidcConfigToJson(_OidcConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'providerName': instance.providerName,
      'issuerUrl': instance.issuerUrl,
      'clientId': instance.clientId,
      'disableInternalAuth': instance.disableInternalAuth,
    };
