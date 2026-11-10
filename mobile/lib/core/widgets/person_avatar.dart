import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/custom_headers.dart';
import '../network/server_address.dart';
import '../network/server_config_provider.dart';
import '../theme/app_typography.dart';
import '../theme/tokens/anchor_tokens.dart';

class PersonAvatar extends ConsumerWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = small,
    this.ring,
  });

  static const double inline = 20; // off-scale: avatar
  static const double small = 24;
  static const double list = 28; // off-scale: avatar
  static const double bar = 30; // off-scale: avatar
  static const double row = 40; // off-scale: avatar
  static const double large = 56; // off-scale: avatar
  static const double profile = 104; // off-scale: avatar

  final String name;
  final String? imageUrl;
  final double size;

  final Color? ring;

  static const List<Color> _colors = [
    AnchorTokens.colorAvatarRust,
    AnchorTokens.colorAvatarBlue,
    AnchorTokens.colorAvatarPurple,
    AnchorTokens.colorAvatarTeal,
    AnchorTokens.colorAvatarOlive,
    AnchorTokens.colorAvatarBrown,
    AnchorTokens.colorAvatarRose,
    AnchorTokens.colorAvatarNavy,
    AnchorTokens.colorAvatarAmber,
    AnchorTokens.colorAvatarIndigo,
    AnchorTokens.colorAvatarMoss,
  ];

  static Color colorFor(String name) {
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return _colors[hash % _colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.watch(serverUrlProvider);
    final customHeaders =
        ref.watch(customHeadersProvider).value ?? const <CustomHeader>[];
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : words.take(2).map((w) => w[0].toUpperCase()).join();
    final url = imageUrl == null || imageUrl!.isEmpty
        ? null
        : imageUrl!.startsWith('http')
        ? imageUrl
        : serverUrl == null
        ? null
        : '$serverUrl$imageUrl';
    final httpHeaders =
        url != null && serverUrl != null && isOnServer(url, serverUrl)
        ? customHeaderMapOf(customHeaders)
        : null;
    final initialsText = Text(
      size < 30 ? initials.substring(0, 1) : initials,
      textScaler: TextScaler.noScaling,
      style: AppTypography.footnote
          .withSize(size * 0.4)
          .copyWith(
            fontWeight: FontWeight.w700,
            color: AnchorTokens.colorAvatarText,
            height: 1,
          ),
    );
    final circle = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorFor(name),
        boxShadow: ring == null
            ? null
            : [BoxShadow(color: ring!, spreadRadius: 2)],
      ),
      alignment: Alignment.center,
      child: url == null
          ? initialsText
          : CachedNetworkImage(
              imageUrl: url,
              httpHeaders: httpHeaders,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fadeInDuration: AnchorTokens.motionDurationFade,
              errorWidget: (_, _, _) => Center(child: initialsText),
            ),
    );
    return ExcludeSemantics(child: circle);
  }
}
