import 'package:anchor/core/router/app_routes.dart';
import 'package:anchor/features/auth/presentation/providers/oidc_config_provider.dart';
import 'package:anchor/features/auth/presentation/providers/registration_mode_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../network/dio_provider.dart';
import '../network/server_config_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/anchor_icon.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  final String? initialUrl;

  const ServerConfigScreen({super.key, this.initialUrl});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isTesting = false;
  bool _isConnecting = false;
  String? _error;

  bool get _isLoading => _isTesting || _isConnecting;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUrl;
    if (initial != null && initial.isNotEmpty) {
      _urlController.text = initial;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleError(Object e) {
    String errorMessage;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Check the URL and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Could not connect to server. Check the URL.';
      } else if (e.type == DioExceptionType.badCertificate) {
        errorMessage =
            'Certificate error. Try enabling "Allow self-signed certificates" below.';
      } else {
        errorMessage = 'Failed to connect to server';
      }
    } else {
      errorMessage = 'Failed to connect to server';
    }
    setState(() {
      _error = errorMessage;
    });
  }

  Future<String?> _prepareUrl() async {
    if (!_formKey.currentState!.validate()) return null;
    String url = _urlController.text.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Dio _getDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    final allowSelfSigned =
        ref.read(allowSelfSignedCertProvider).value ?? false;
    final url = _urlController.text.trim();
    if (allowSelfSigned && url.isNotEmpty) {
      dio.httpClientAdapter = createSelfSignedCertAdapter(url);
    }
    return dio;
  }

  Future<void> _testConnection() async {
    final url = await _prepareUrl();
    if (url == null) return;

    setState(() {
      _isTesting = true;
      _error = null;
    });

    try {
      final dio = _getDio();
      final response = await dio.get('$url/api/health');

      if (response.statusCode == 200 && response.data['app'] == 'anchor') {
        final version = response.data['version'] ?? 'Unknown';
        if (mounted) {
          AppSnackbar.showSuccess(
            context,
            message: 'Server is running! Version: $version',
          );
        }
      } else {
        setState(() {
          _error = 'Invalid server response. Is this an Anchor server?';
        });
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _connect() async {
    final url = await _prepareUrl();
    if (url == null) return;

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final dio = _getDio();
      final response = await dio.get('$url/api/health');

      if (response.statusCode == 200 && response.data['app'] == 'anchor') {
        final shouldPop = widget.initialUrl != null;
        final notifier = ref.read(serverConfigProvider.notifier);

        if (mounted) {
          if (shouldPop) {
            context.pop();
          } else {
            context.go(AppRoutes.login);
          }
        }

        await notifier.setServerUrl(url);
        ref.invalidate(oidcConfigProvider);
        ref.invalidate(registrationModeProvider);
      } else {
        setState(() {
          _error = 'Invalid server response. Is this an Anchor server?';
        });
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the server URL';
    }

    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        return 'Please enter a valid URL';
      }
    } catch (_) {
      return 'Please enter a valid URL';
    }

    return null;
  }
  void _showAddHeaderDialog({int? editIndex, CustomHeader? existing}) {
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    final valueCtrl = TextEditingController(text: existing?.value ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            editIndex != null ? 'Edit Header' : 'Add Header',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: keyCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'X-Custom-Header',
                  prefixIcon: const Icon(LucideIcons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueCtrl,
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: 'header-value',
                  prefixIcon: const Icon(LucideIcons.text),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                autocorrect: false,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final k = keyCtrl.text.trim();
                final v = valueCtrl.text;
                if (k.isEmpty) return;
                final header = CustomHeader(key: k, value: v);
                final notifier =
                    ref.read(customHeadersProvider.notifier);
                if (editIndex != null) {
                  notifier.updateHeader(editIndex, header);
                } else {
                  notifier.addHeader(header);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(editIndex != null ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowSelfSigned =
        ref.watch(allowSelfSignedCertProvider).value ?? false;
    final customHeaders = ref.watch(customHeadersProvider).value ?? [];
    final canAddMore = customHeaders.length < maxCustomHeaders;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AnchorIcon(size: 100)),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    'Connect to Server',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Enter your Anchor server URL to get started',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // URL Input
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://your-server.com',
                      prefixIcon: const Icon(LucideIcons.globe),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      helperText: 'Example: https://anchor.example.com',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: _validateUrl,
                  ),
                  const SizedBox(height: 8),

                  // Self-signed certificate toggle
                  Row(
                    children: [
                      Icon(
                        LucideIcons.shieldOff,
                        size: 18,
                        color: allowSelfSigned
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allow self-signed certificates',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (allowSelfSigned)
                              Text(
                                'Warning: Connection security is reduced',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: allowSelfSigned,
                        onChanged: (value) {
                          ref
                              .read(allowSelfSignedCertProvider.notifier)
                              .toggle(value);
                          if (value && mounted) {
                            AppSnackbar.showWarning(
                              context,
                              message:
                                  'Self-signed certificates are now accepted. This reduces connection security.',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Custom headers section
                  _CustomHeadersSection(
                    headers: customHeaders,
                    canAddMore: canAddMore,
                    onAdd: () => _showAddHeaderDialog(),
                    onEdit: (i) => _showAddHeaderDialog(
                      editIndex: i,
                      existing: customHeaders[i],
                    ),
                    onRemove: (i) =>
                        ref.read(customHeadersProvider.notifier).removeHeader(i),
                  ),
                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.wifi),
                          label: const Text('Test'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _connect,
                          icon: _isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(LucideIcons.arrowRight),
                          label: const Text('Connect'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Anchor is self-hosted. You need to run your own server to use this app.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _CustomHeadersSection extends StatelessWidget {
  final List<CustomHeader> headers;
  final bool canAddMore;
  final VoidCallback onAdd;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;
  const _CustomHeadersSection({
    required this.headers,
    required this.canAddMore,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section row: icon + label + "Add" button
        Row(
          children: [
            Icon(
              LucideIcons.sliders,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Custom headers',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (canAddMore)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              )
            else
              Text(
                'Max $maxCustomHeaders reached',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
        if (headers.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < headers.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                  _HeaderRow(
                    header: headers[i],
                    onEdit: () => onEdit(i),
                    onRemove: () => onRemove(i),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            'No custom headers added.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ],
    );
  }
}
class _HeaderRow extends StatelessWidget {
  final CustomHeader header;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _HeaderRow({
    required this.header,
    required this.onEdit,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.tag,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      header.key,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      header.value.isEmpty ? '(empty)' : header.value,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: header.value.isEmpty
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }
}