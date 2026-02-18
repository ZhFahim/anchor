import 'package:freezed_annotation/freezed_annotation.dart';

part 'oidc_config.freezed.dart';
part 'oidc_config.g.dart';

/// OIDC configuration
@freezed
abstract class OidcConfig with _$OidcConfig {
  const factory OidcConfig({
    @Default(false) bool enabled,
    @Default('OIDC Provider') String providerName,
    String? issuerUrl,
    String? clientId,
    @Default(false) bool disableInternalAuth,
  }) = _OidcConfig;

  factory OidcConfig.fromJson(Map<String, dynamic> json) =>
      _$OidcConfigFromJson(json);
}
