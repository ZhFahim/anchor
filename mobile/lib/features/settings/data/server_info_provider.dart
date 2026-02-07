import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_provider.dart';

part 'server_info_provider.g.dart';

class ServerInfo {
  final String version;
  final String app;

  ServerInfo({required this.version, required this.app});

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      version: json['version'] as String? ?? 'Unknown',
      app: json['app'] as String? ?? 'Unknown',
    );
  }
}

@riverpod
Future<ServerInfo?> serverInfo(Ref ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/api/health');
    
    if (response.statusCode == 200) {
      return ServerInfo.fromJson(response.data);
    }
    return null;
  } catch (e) {
    // Return null if we can't fetch server info (e.g., offline)
    return null;
  }
}
