typedef AppSyncRequester = Future<void> Function();

AppSyncRequester? _appSyncRequester;

void registerAppSyncRequester(AppSyncRequester? requester) {
  _appSyncRequester = requester;
}

Future<void> requestAppSync() async {
  final requester = _appSyncRequester;
  if (requester == null) return;
  await requester();
}

void scheduleAppSync() {
  final requester = _appSyncRequester;
  if (requester == null) return;
  requester();
}
