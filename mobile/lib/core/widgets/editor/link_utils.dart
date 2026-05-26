import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_snackbar.dart';

const _schemes = [
  'http://',
  'https://',
  'mailto:',
  'tel:',
  'sms:',
  'ftp://',
  'ftps://',
  'file://',
  'geo:',
];

final _hostLike = RegExp(
  r'^([\w-]+(\.[\w-]+)+|localhost)(:\d+)?([/?#].*)?$',
  caseSensitive: false,
);

String normalizeUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();
  for (final scheme in _schemes) {
    if (lower.startsWith(scheme)) return trimmed;
  }
  if (_hostLike.hasMatch(trimmed)) return 'https://$trimmed';
  return trimmed;
}

bool isLikelyUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.contains(' ')) return false;
  final lower = trimmed.toLowerCase();
  for (final scheme in _schemes) {
    if (lower.startsWith(scheme)) return true;
  }
  return _hostLike.hasMatch(trimmed);
}

Future<void> launchExternal(BuildContext context, String url) async {
  final normalized = normalizeUrl(url);
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    if (context.mounted) {
      AppSnackbar.showError(context, message: 'Invalid link');
    }
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.showError(context, message: "Couldn't open link");
    }
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.showError(context, message: "Couldn't open link");
    }
  }
}

({String url, String text, int start, int length})? linkAtSelection(
  QuillController controller,
) {
  final sel = controller.selection;
  if (!sel.isValid || sel.baseOffset < 0) return null;
  final offset = sel.baseOffset;

  final ops = controller.document.toDelta().toList();
  var pos = 0;
  var hitIndex = -1;
  String? hitUrl;
  String hitText = '';

  for (var i = 0; i < ops.length; i++) {
    final op = ops[i];
    final data = op.data;
    if (data is! String) {
      pos += op.length ?? 0;
      continue;
    }
    if (offset >= pos && offset <= pos + data.length) {
      final url = op.attributes?['link'] as String?;
      if (url != null && url.isNotEmpty) {
        hitIndex = i;
        hitUrl = url;
        hitText = data;
        break;
      }
      if (offset < pos + data.length) return null;
    }
    pos += data.length;
  }

  if (hitIndex < 0 || hitUrl == null) return null;

  var start = pos;
  final left = <String>[];
  for (var i = hitIndex - 1; i >= 0; i--) {
    final data = ops[i].data;
    if (data is! String) break;
    if ((ops[i].attributes?['link'] as String?) != hitUrl) break;
    left.add(data);
    start -= data.length;
  }

  final buffer = StringBuffer()
    ..writeAll(left.reversed)
    ..write(hitText);
  for (var i = hitIndex + 1; i < ops.length; i++) {
    final data = ops[i].data;
    if (data is! String) break;
    if ((ops[i].attributes?['link'] as String?) != hitUrl) break;
    buffer.write(data);
  }

  final text = buffer.toString();
  return (url: hitUrl, text: text, start: start, length: text.length);
}
