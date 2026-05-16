import '../logging/app_logger.dart';

typedef AppSyncRequester = Future<void> Function();

AppSyncRequester? _appSyncRequester;

void registerAppSyncRequester(AppSyncRequester? requester) {
  _appSyncRequester = requester;
}

/// Awaits a full sync cycle. Pass [trigger] so logs show who asked.
Future<void> requestAppSync({String trigger = 'unknown'}) async {
  final requester = _appSyncRequester;
  if (requester == null) {
    AppLogger.instance.debug(
      'Sync',
      'requestAppSync($trigger): no requester registered, skipping',
    );
    return;
  }
  AppLogger.instance.info('Sync', 'requestAppSync($trigger)');
  await requester();
}

/// Fire-and-forget variant. Pass [trigger] so logs show who asked.
void scheduleAppSync({String trigger = 'unknown'}) {
  final requester = _appSyncRequester;
  if (requester == null) {
    AppLogger.instance.debug(
      'Sync',
      'scheduleAppSync($trigger): no requester registered, skipping',
    );
    return;
  }
  AppLogger.instance.info('Sync', 'scheduleAppSync($trigger)');
  requester();
}
