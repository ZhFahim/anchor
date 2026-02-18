// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'oidc_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OidcConfig {

 bool get enabled; String? get providerName; String? get issuerUrl; String? get clientId; bool get disableInternalAuth;
/// Create a copy of OidcConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OidcConfigCopyWith<OidcConfig> get copyWith => _$OidcConfigCopyWithImpl<OidcConfig>(this as OidcConfig, _$identity);

  /// Serializes this OidcConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OidcConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.issuerUrl, issuerUrl) || other.issuerUrl == issuerUrl)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.disableInternalAuth, disableInternalAuth) || other.disableInternalAuth == disableInternalAuth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,providerName,issuerUrl,clientId,disableInternalAuth);

@override
String toString() {
  return 'OidcConfig(enabled: $enabled, providerName: $providerName, issuerUrl: $issuerUrl, clientId: $clientId, disableInternalAuth: $disableInternalAuth)';
}


}

/// @nodoc
abstract mixin class $OidcConfigCopyWith<$Res>  {
  factory $OidcConfigCopyWith(OidcConfig value, $Res Function(OidcConfig) _then) = _$OidcConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, String? providerName, String? issuerUrl, String? clientId, bool disableInternalAuth
});




}
/// @nodoc
class _$OidcConfigCopyWithImpl<$Res>
    implements $OidcConfigCopyWith<$Res> {
  _$OidcConfigCopyWithImpl(this._self, this._then);

  final OidcConfig _self;
  final $Res Function(OidcConfig) _then;

/// Create a copy of OidcConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? providerName = freezed,Object? issuerUrl = freezed,Object? clientId = freezed,Object? disableInternalAuth = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,providerName: freezed == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String?,issuerUrl: freezed == issuerUrl ? _self.issuerUrl : issuerUrl // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,disableInternalAuth: null == disableInternalAuth ? _self.disableInternalAuth : disableInternalAuth // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OidcConfig].
extension OidcConfigPatterns on OidcConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OidcConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OidcConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OidcConfig value)  $default,){
final _that = this;
switch (_that) {
case _OidcConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OidcConfig value)?  $default,){
final _that = this;
switch (_that) {
case _OidcConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String? providerName,  String? issuerUrl,  String? clientId,  bool disableInternalAuth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OidcConfig() when $default != null:
return $default(_that.enabled,_that.providerName,_that.issuerUrl,_that.clientId,_that.disableInternalAuth);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String? providerName,  String? issuerUrl,  String? clientId,  bool disableInternalAuth)  $default,) {final _that = this;
switch (_that) {
case _OidcConfig():
return $default(_that.enabled,_that.providerName,_that.issuerUrl,_that.clientId,_that.disableInternalAuth);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String? providerName,  String? issuerUrl,  String? clientId,  bool disableInternalAuth)?  $default,) {final _that = this;
switch (_that) {
case _OidcConfig() when $default != null:
return $default(_that.enabled,_that.providerName,_that.issuerUrl,_that.clientId,_that.disableInternalAuth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OidcConfig implements OidcConfig {
  const _OidcConfig({this.enabled = false, this.providerName, this.issuerUrl, this.clientId, this.disableInternalAuth = false});
  factory _OidcConfig.fromJson(Map<String, dynamic> json) => _$OidcConfigFromJson(json);

@override@JsonKey() final  bool enabled;
@override final  String? providerName;
@override final  String? issuerUrl;
@override final  String? clientId;
@override@JsonKey() final  bool disableInternalAuth;

/// Create a copy of OidcConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OidcConfigCopyWith<_OidcConfig> get copyWith => __$OidcConfigCopyWithImpl<_OidcConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OidcConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OidcConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.issuerUrl, issuerUrl) || other.issuerUrl == issuerUrl)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.disableInternalAuth, disableInternalAuth) || other.disableInternalAuth == disableInternalAuth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,providerName,issuerUrl,clientId,disableInternalAuth);

@override
String toString() {
  return 'OidcConfig(enabled: $enabled, providerName: $providerName, issuerUrl: $issuerUrl, clientId: $clientId, disableInternalAuth: $disableInternalAuth)';
}


}

/// @nodoc
abstract mixin class _$OidcConfigCopyWith<$Res> implements $OidcConfigCopyWith<$Res> {
  factory _$OidcConfigCopyWith(_OidcConfig value, $Res Function(_OidcConfig) _then) = __$OidcConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String? providerName, String? issuerUrl, String? clientId, bool disableInternalAuth
});




}
/// @nodoc
class __$OidcConfigCopyWithImpl<$Res>
    implements _$OidcConfigCopyWith<$Res> {
  __$OidcConfigCopyWithImpl(this._self, this._then);

  final _OidcConfig _self;
  final $Res Function(_OidcConfig) _then;

/// Create a copy of OidcConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? providerName = freezed,Object? issuerUrl = freezed,Object? clientId = freezed,Object? disableInternalAuth = null,}) {
  return _then(_OidcConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,providerName: freezed == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String?,issuerUrl: freezed == issuerUrl ? _self.issuerUrl : issuerUrl // ignore: cast_nullable_to_non_nullable
as String?,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String?,disableInternalAuth: null == disableInternalAuth ? _self.disableInternalAuth : disableInternalAuth // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
