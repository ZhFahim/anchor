// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Anchor 笔记';

  @override
  String get commonBack => '返回';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDone => '完成';

  @override
  String get commonMenu => '菜单';

  @override
  String get commonCloseMenu => '关闭菜单';

  @override
  String get commonShowPassword => '显示密码';

  @override
  String get commonHidePassword => '隐藏密码';

  @override
  String get commonSelectedNotes => '已选笔记';

  @override
  String get commonPlay => '播放';

  @override
  String get commonPause => '暂停';

  @override
  String commonPlayItem(String name) {
    return '播放 $name';
  }

  @override
  String commonPauseItem(String name) {
    return '暂停 $name';
  }

  @override
  String commonSwitchOn(String label) {
    return '$label，已开启';
  }

  @override
  String commonSwitchOff(String label) {
    return '$label，已关闭';
  }

  @override
  String get formOffline => '你处于离线状态。请连接网络后继续。';

  @override
  String get linkInvalid => '链接无效';

  @override
  String get linkCantOpen => '无法打开链接';

  @override
  String get densityDefault => '默认';

  @override
  String get densityCompact => '紧凑';

  @override
  String get noteFontSans => '无衬线';

  @override
  String get noteFontSerif => '衬线';

  @override
  String get noteFontMono => '等宽';

  @override
  String get textSizeSmall => '小';

  @override
  String get textSizeDefault => '默认';

  @override
  String get textSizeLarge => '大';

  @override
  String get errorOffline => '没有网络连接。';

  @override
  String get errorTimeout => '服务器响应超时。';

  @override
  String get errorCertificate => '服务器证书不受信任。';

  @override
  String get errorCancelled => '请求已取消。';

  @override
  String get errorSignInAgain => '请重新登录后继续。';

  @override
  String get errorForbidden => '你没有执行此操作的权限。';

  @override
  String get errorNotFound => '找不到该项目。';

  @override
  String get errorIncompatible => '此应用与你的服务器不兼容，请更新后继续。';

  @override
  String get errorCheckInput => '请检查你填写的信息。';

  @override
  String get errorGeneric => '出了点问题，请重试。';

  @override
  String get errorServer => '服务器出现问题，请稍后再试。';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaving => '正在保存…';

  @override
  String get commonUndo => '撤销';

  @override
  String get fieldName => '姓名';

  @override
  String get fieldNameHint => '你的名字';

  @override
  String get fieldEmail => '邮箱';

  @override
  String get fieldEmailHint => 'you@example.com';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldCurrentPassword => '当前密码';

  @override
  String get fieldNewPassword => '新密码';

  @override
  String passwordHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '至少 $count 个字符。',
    );
    return '$_temp0';
  }

  @override
  String get authEnterName => '请输入你的名字。';

  @override
  String get authEnterEmail => '请输入你的邮箱地址。';

  @override
  String get authEnterValidEmail => '请输入有效的邮箱地址。';

  @override
  String get authEnterPassword => '请输入你的密码。';

  @override
  String get authEnterCurrentPassword => '请输入当前密码。';

  @override
  String authPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请至少使用 $count 个字符。',
    );
    return '$_temp0';
  }

  @override
  String get authIncorrectCredentials => '邮箱或密码不正确。';

  @override
  String get authPasswordless => '此账户不使用密码，请改用你的登录服务商登录。';

  @override
  String get authPendingApproval => '你的账户正在等待管理员批准。';

  @override
  String authPasswordSignInOff(String provider) {
    return '邮箱和密码登录已关闭，请使用 $provider 登录。';
  }

  @override
  String authPasswordSignUpOff(String provider) {
    return '邮箱和密码注册已关闭，请使用 $provider 注册。';
  }

  @override
  String get authPasswordSignInOffHere => '此服务器已关闭邮箱和密码登录。';

  @override
  String get authPasswordSignUpOffHere => '此服务器已关闭邮箱和密码注册。';

  @override
  String get authRegistrationClosed => '此服务器不接受新账户。';

  @override
  String get authEmailTaken => '该邮箱已注册账户。';

  @override
  String get authLastAdmin => '你是此服务器唯一的管理员，请先将其他人设为管理员。';

  @override
  String get authWrongCurrentPassword => '当前密码不正确。';

  @override
  String get authSamePassword => '新密码必须与当前密码不同。';

  @override
  String get authUnreachable => '无法连接你的服务器，请检查网络后重试。';

  @override
  String get authProviderNotSetUp => '此服务器未设置登录服务商。';

  @override
  String get authProviderFailed => '无法通过你的服务商登录，请重试。';

  @override
  String authProviderFailedWith(String detail) {
    return '无法通过你的服务商登录：$detail';
  }

  @override
  String get authSignIn => '登录';

  @override
  String get authSigningIn => '正在登录…';

  @override
  String authContinueWith(String provider) {
    return '使用 $provider 继续';
  }

  @override
  String authOpeningProvider(String provider) {
    return '正在打开 $provider…';
  }

  @override
  String get authWelcomeBack => '欢迎回来';

  @override
  String get authSignInToAnchor => '登录以继续使用 Anchor。';

  @override
  String authSignInTo(String server) {
    return '登录 $server';
  }

  @override
  String get authOfflineSignIn => '你处于离线状态，请连接网络后登录。';

  @override
  String get authNewToAnchor => '第一次使用 Anchor？';

  @override
  String get authCreateAnAccount => '创建账户';

  @override
  String get authOr => '或';

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authCreatingAccount => '正在创建账户…';

  @override
  String get authCreateYourAccount => '创建你的账户';

  @override
  String get authApprovalNeeded => '新账户需要管理员批准后才能登录。';

  @override
  String get authRegisterSubtitle => '开始记录你的想法。';

  @override
  String get authAlreadyHaveAccount => '已有账户？';

  @override
  String authWelcomeName(String name) {
    return '欢迎使用 Anchor，$name';
  }

  @override
  String get authWaitingTitle => '等待批准';

  @override
  String get authWaitingMessage => '管理员批准你的账户后即可登录。';

  @override
  String get authBackToSignIn => '返回登录';

  @override
  String get deleteAccountTitle => '删除账户';

  @override
  String get deleteAccountWarning => '此操作无法撤销。';

  @override
  String get deleteAccountMessage =>
      '你的账户、笔记、标签、附件和提醒将从此服务器永久删除。你共享过的笔记将不再对其他人可用。';

  @override
  String get deleteAccountExport => '如需保留笔记副本，请先在网页版的设置中导出。';

  @override
  String get deleteAccountPasswordHelp => '请输入密码以确认。';

  @override
  String get deleteAccountConfirm => '删除账户';

  @override
  String get deleteAccountDeleting => '正在删除…';

  @override
  String get deleteAccountDone => '账户已删除';

  @override
  String get deleteAccountOffline => '你处于离线状态，请连接网络后删除账户。';

  @override
  String get deleteAccountDialogTitle => '删除你的账户？';

  @override
  String get deleteAccountDialogMessage => '你的账户和笔记将从此服务器永久删除。';

  @override
  String get passwordTitle => '密码';

  @override
  String get passwordChange => '修改密码';

  @override
  String get passwordChanging => '正在修改…';

  @override
  String get passwordChanged => '密码已修改';

  @override
  String get passwordOffline => '你处于离线状态，请连接网络后修改密码。';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileSaved => '个人资料已保存';

  @override
  String get profileOffline => '你处于离线状态，请连接网络后修改个人资料。';

  @override
  String get profilePhoto => '头像';

  @override
  String get profilePhotoVisible => '与你共享笔记的人可以看到。';

  @override
  String get profileTakePhoto => '拍照';

  @override
  String get profileChoosePhoto => '选择照片';

  @override
  String get profileRemovePhoto => '移除照片';

  @override
  String get profilePhotoUpdated => '照片已更新';

  @override
  String get profilePhotoUpdateFailed => '无法更新你的照片';

  @override
  String get profilePhotoRemoved => '照片已移除';

  @override
  String get profilePhotoRemoveFailed => '无法移除你的照片';

  @override
  String get profileEmailAdminOnly => '只有管理员可以修改你的邮箱。';

  @override
  String get profileChangePhoto => '更换头像';

  @override
  String get commonContinue => '继续';

  @override
  String commonExpandedItem(String label) {
    return '$label，已展开';
  }

  @override
  String commonCollapsedItem(String label) {
    return '$label，已折叠';
  }

  @override
  String get serverTitle => '服务器';

  @override
  String get serverWelcome => '欢迎使用 Anchor';

  @override
  String get serverSubtitle => '输入你的服务器地址以开始。';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get serverAddressHint => 'notes.example.com';

  @override
  String get serverConnecting => '正在连接…';

  @override
  String get serverAdvanced => '高级';

  @override
  String get serverSelfSigned => '允许自签名证书';

  @override
  String get serverSelfSignedWarning => '仅用于你自行管理的服务器，Anchor 无法验证其身份。';

  @override
  String get serverCustomHeaders => '自定义请求头';

  @override
  String get serverCustomHeadersHint =>
      '随每个请求发送。用于服务器前置的代理，例如 Cloudflare Access。';

  @override
  String get serverAddHeader => '添加请求头';

  @override
  String get serverRemoveHeader => '移除请求头';

  @override
  String serverRemoveNamedHeader(String name) {
    return '移除 $name';
  }

  @override
  String get serverHeaderRemoved => '请求头已移除';

  @override
  String get serverHeaderNameLabel => '请求头名称';

  @override
  String get serverHeaderValueLabel => '请求头值';

  @override
  String get serverShowHeaderValue => '显示值';

  @override
  String get serverHideHeaderValue => '隐藏值';

  @override
  String get serverHeaderNameHint => '名称';

  @override
  String get serverHeaderValueHint => '值';

  @override
  String serverHeaderLimit(int max) {
    return '最多 $max 个请求头。';
  }

  @override
  String get serverHeaderMissingName => '请输入请求头名称。';

  @override
  String get serverHeaderInvalidName => '请输入有效的请求头名称。';

  @override
  String get serverHeaderInvalidValue => '请输入有效的请求头值。';

  @override
  String get serverHeaderReserved => '此请求头由 Anchor 自行设置。';

  @override
  String get serverHeaderDuplicate => '此请求头已添加。';

  @override
  String get serverSelfHosted => 'Anchor 需要自托管服务器。';

  @override
  String get serverEnterAddress => '请输入服务器地址。';

  @override
  String get serverEnterValidAddress => '请输入有效的服务器地址。';

  @override
  String get serverConnectFailed => '无法连接到服务器，请重试。';

  @override
  String serverNotAnchor(String host) {
    return '$host 不是 Anchor 服务器，请检查地址。';
  }

  @override
  String serverUntrusted(String host) {
    return '无法验证 $host 的证书。如果是自签名证书，请在“高级”中开启“允许自签名证书”。';
  }

  @override
  String serverUnreachableNoScheme(String host) {
    return '无法连接 $host。请检查地址；如果你的服务器不使用 https，请在地址前加上 http://。';
  }

  @override
  String serverUnreachable(String host) {
    return '无法连接 $host，请检查地址和网络连接。';
  }

  @override
  String get serverConnectAnyway => '仍然连接';

  @override
  String serverLinkLabel(String host) {
    return '服务器 $host。更换服务器';
  }

  @override
  String get commonMore => '更多';

  @override
  String get commonCopy => '复制';

  @override
  String get commonSelect => '选择';

  @override
  String get commonSelectAll => '全选';

  @override
  String get commonDeselectAll => '取消全选';

  @override
  String get commonStopSelecting => '退出选择';

  @override
  String commonSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String settingsProfileCard(String name, String email) {
    return '$name，$email。个人资料';
  }

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsDensity => '密度';

  @override
  String get settingsDensityHelp => '紧凑模式可在屏幕上显示更多笔记。';

  @override
  String get settingsTheme => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAutomatic => '自动';

  @override
  String get settingsEditor => '编辑器';

  @override
  String get settingsFont => '字体';

  @override
  String get settingsTextSize => '文字大小';

  @override
  String get settingsMoveChecked => '将已勾选项目移至底部';

  @override
  String get settingsMoveCheckedHelp => '已勾选的条目会移到未勾选的条目下方。';

  @override
  String get settingsPreviewTitle => '里斯本周末';

  @override
  String get settingsPreviewText => '轻装出行。山路陡峭，电车到九点就挤满了。';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsPassword => '密码';

  @override
  String settingsPasswordManaged(String provider) {
    return '你的密码由 $provider 管理。';
  }

  @override
  String get settingsPasswordManagedElsewhere => '你的密码由登录服务商管理。';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsDeleteAccount => '删除账户';

  @override
  String get settingsSigningOut => '正在退出…';

  @override
  String get settingsSignOutTitle => '退出登录？';

  @override
  String settingsSignOutMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项更改尚未同步，它们会留在这台手机上，登录后再次同步。',
    );
    return '$_temp0';
  }

  @override
  String get settingsHelp => '帮助';

  @override
  String get settingsLogs => '日志';

  @override
  String get settingsLogsHelp => '用于排查问题的活动详情';

  @override
  String get settingsSupport => '支持 Anchor';

  @override
  String get settingsSupportHelp => '请开发者喝杯咖啡';

  @override
  String get settingsOffline => '离线。更改已保存在这台手机上。';

  @override
  String settingsSyncPaused(String reason) {
    return '同步已暂停。$reason';
  }

  @override
  String settingsCantReach(String host) {
    return '无法连接 $host';
  }

  @override
  String settingsConnectedTo(String host) {
    return '已连接到 $host';
  }

  @override
  String settingsConnectedToVersion(String host, String version) {
    return '已连接到 $host · 服务器 $version';
  }

  @override
  String settingsAppVersion(String version) {
    return 'Anchor $version';
  }

  @override
  String get settingsAppNameShort => 'Anchor';

  @override
  String get settingsTagline => '你的想法，安全保存。';

  @override
  String get logsTitle => '日志';

  @override
  String get logsMenuHelp => '复制和保存也会包含更早的会话。';

  @override
  String get logsCopyAll => '全部复制';

  @override
  String get logsSaveToFile => '保存到文件';

  @override
  String get logsClear => '清除日志';

  @override
  String get logsCopiedAll => '日志已复制，包括更早的会话';

  @override
  String get logsCopiedNewest => '已复制最新的日志。如需全部日志，请保存到文件。';

  @override
  String get logsClearTitle => '清除日志？';

  @override
  String get logsClearMessage => '这台手机上的所有日志都将被删除，此操作无法撤销。';

  @override
  String get logsCleared => '日志已清除';

  @override
  String get logsSaveDialog => '保存日志';

  @override
  String logsSaved(String name) {
    return '已保存 $name';
  }

  @override
  String get logsSaveFailed => '无法保存日志';

  @override
  String logsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已复制 $count 条日志',
    );
    return '$_temp0';
  }

  @override
  String get logsSelectTitle => '选择日志';

  @override
  String get logsSearch => '搜索日志';

  @override
  String get logsSelected => '已选日志';

  @override
  String get logsLevel => '日志级别';

  @override
  String get logsAll => '全部';

  @override
  String get logsErrors => '错误';

  @override
  String get logsWarnings => '警告';

  @override
  String get logsInfo => '信息';

  @override
  String get logsDebug => '调试';

  @override
  String get logsSessionNote => '仅显示本次会话。复制和保存也会包含更早的会话。';

  @override
  String get logsNoMatches => '没有匹配的日志';

  @override
  String get logsNoMatchesHelp => '换个关键词，或显示所有级别。';

  @override
  String get logsEmpty => '还没有日志';

  @override
  String get logsEmptyHelp => '本次会话的活动会显示在这里。';

  @override
  String get logLevelError => '错误';

  @override
  String get logLevelWarning => '警告';

  @override
  String get logLevelInfo => '信息';

  @override
  String get logLevelDebug => '调试';

  @override
  String get commonToday => '今天';

  @override
  String get commonTomorrow => '明天';

  @override
  String get commonNotNow => '暂不';

  @override
  String get commonLater => '以后';

  @override
  String get commonOk => '好';

  @override
  String get commonOpenSettings => '打开设置';

  @override
  String get reminderTitle => '提醒';

  @override
  String get reminderSheetSubtitle => '你会在这台手机上收到通知。';

  @override
  String reminderDayTime(String day, String time) {
    return '$day $time';
  }

  @override
  String reminderWithRepeat(String when, String repeat) {
    return '$when · $repeat';
  }

  @override
  String reminderSpoken(String when) {
    return '提醒：$when';
  }

  @override
  String reminderSpokenLate(String when) {
    return '已过期的提醒：$when';
  }

  @override
  String get reminderLaterToday => '今天晚些时候';

  @override
  String get reminderNextWeek => '下周';

  @override
  String get reminderNone => '无提醒';

  @override
  String get reminderPickTime => '选择日期和时间';

  @override
  String get reminderTimePassed => '此时间已过';

  @override
  String reminderInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟后',
    );
    return '$_temp0';
  }

  @override
  String reminderInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时后',
    );
    return '$_temp0';
  }

  @override
  String reminderInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天后',
    );
    return '$_temp0';
  }

  @override
  String get reminderRepeatsDaily => '每天重复';

  @override
  String reminderRepeatsWeekly(String weekday) {
    return '每$weekday重复';
  }

  @override
  String reminderRepeatsMonthly(int day) {
    return '每月 $day 日重复';
  }

  @override
  String reminderRepeatsMonthlyEnd(int day) {
    return '每月 $day 日或月末重复';
  }

  @override
  String reminderRepeatsYearly(String date) {
    return '每年 $date 重复';
  }

  @override
  String get repeatOnce => '一次';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每周';

  @override
  String get repeatMonthly => '每月';

  @override
  String get repeatYearly => '每年';

  @override
  String get reminderWhen => '时间';

  @override
  String get reminderPickDate => '选择日期';

  @override
  String get reminderDate => '日期';

  @override
  String get reminderTime => '时间';

  @override
  String get reminderRepeat => '重复';

  @override
  String get reminderRemove => '移除';

  @override
  String get reminderSetFailed => '无法设置提醒';

  @override
  String get reminderNotifyTitle => '允许通知？';

  @override
  String get reminderNotifyMessage => 'Anchor 需要通知权限，你的提醒才能在这台手机上响起。';

  @override
  String get reminderExactTitle => '允许精确闹钟？';

  @override
  String get reminderExactMessage => 'Android 可能会为省电而延迟提醒。请允许精确闹钟，让提醒准时响起。';

  @override
  String get reminderNotificationsOff => '通知已关闭，请在手机设置中开启。';

  @override
  String get monthPrevious => '上个月';

  @override
  String get monthNext => '下个月';

  @override
  String get reminderChannelName => '提醒';

  @override
  String get reminderChannelDescription => '你在笔记中设置的提醒';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => '标签';

  @override
  String get tagNotesTitle => '给笔记打标签';

  @override
  String get tagSaveFailed => '无法保存标签';

  @override
  String get tagUpdateFailed => '无法更新标签';

  @override
  String tagNameTaken(String name) {
    return '名为“$name”的标签已存在。';
  }

  @override
  String tagCreateNamed(String name) {
    return '创建“$name”';
  }

  @override
  String tagAdded(String tag) {
    return '$tag，已添加';
  }

  @override
  String tagNotAdded(String tag) {
    return '$tag，未添加';
  }

  @override
  String tagAddedToSome(String tag) {
    return '$tag，已添加到部分笔记';
  }

  @override
  String get tagSearchOrCreate => '搜索或创建标签';

  @override
  String get tagsEmpty => '还没有标签。输入名称即可创建。';

  @override
  String tagSheetLabel(String name) {
    return '标签 $name';
  }

  @override
  String get tagColor => '颜色';

  @override
  String get tagRename => '重命名标签';

  @override
  String get tagDelete => '删除标签';

  @override
  String tagDeleteTitle(String name) {
    return '删除标签“$name”？';
  }

  @override
  String tagDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '该标签将从 $count 条笔记中移除，笔记本身不会被删除。',
    );
    return '$_temp0';
  }

  @override
  String get tagDeleteUnused => '此标签未用于任何笔记。';

  @override
  String tagDeleted(String name) {
    return '标签“$name”已删除';
  }

  @override
  String get tagNew => '新建标签';

  @override
  String get tagNamePreview => '标签名';

  @override
  String get tagNameHint => '标签名称';

  @override
  String get tagCreate => '创建标签';

  @override
  String get tagRenameAction => '重命名';

  @override
  String get colorRed => '红色';

  @override
  String get colorPink => '粉色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorDeepPurple => '深紫色';

  @override
  String get colorIndigo => '靛蓝色';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorLightBlue => '浅蓝色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorTeal => '蓝绿色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorLightGreen => '浅绿色';

  @override
  String get colorLime => '黄绿色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorDeepOrange => '深橙色';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorBlueGrey => '蓝灰色';

  @override
  String get colorYellow => '黄色';

  @override
  String get syncSignedOutLead => '已退出登录。';

  @override
  String get syncSignedOutText => '请重新登录以同步笔记。';

  @override
  String get syncSignInAgainTitle => '重新登录';

  @override
  String get syncSignInAgainMessage => '你的笔记会留在这台手机上，登录后即可同步。';

  @override
  String get syncServerOutdatedLead => '请更新服务器。';

  @override
  String get syncServerOutdatedText => '服务器版本太旧，无法与此应用同步。';

  @override
  String get syncServerOutdatedTitle => '更新服务器';

  @override
  String get syncServerOutdatedMessage =>
      '你的 Anchor 服务器版本太旧，无法与此应用同步。请更新服务器后继续。';

  @override
  String get syncAppOutdatedLead => '请更新 Anchor。';

  @override
  String get syncAppOutdatedText => '此应用版本太旧，无法与你的服务器同步。';

  @override
  String get syncAppOutdatedTitle => '更新 Anchor';

  @override
  String get syncAppOutdatedMessage => '此应用版本太旧，无法与你的 Anchor 服务器同步。请更新应用后继续。';

  @override
  String syncPausedMessage(String reason) {
    return '$reason 在此期间，你的笔记会留在这台手机上。';
  }

  @override
  String get reminderAdd => '添加提醒';

  @override
  String get commonYesterday => '昨天';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人',
    );
    return '$_temp0';
  }

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个词',
    );
    return '$_temp0';
  }

  @override
  String get notesSelectTitle => '选择笔记';

  @override
  String get noteUntitled => '无标题';

  @override
  String namesTwo(String first, String second) {
    return '$first 和 $second';
  }

  @override
  String namesMore(String first, String second, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$first、$second 以及另外 $count 人',
    );
    return '$_temp0';
  }

  @override
  String get shareOnlyYou => '只有你可以看到这条笔记。';

  @override
  String get shareLoadFailed => '无法加载有访问权限的人。';

  @override
  String shareSharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已共享给 $count 人。',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已共享给 $count 人。连接网络后可查看具体是谁。',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithNames(String names) {
    return '已共享给 $names';
  }

  @override
  String shareSharedWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已共享给 $count 人',
    );
    return '$_temp0';
  }

  @override
  String get shareCanView => '可查看';

  @override
  String get shareCanEdit => '可编辑';

  @override
  String dayTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String dayYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String dayOnAt(String date, String time) {
    return '$date $time';
  }

  @override
  String get editedToday => '今天编辑';

  @override
  String get editedYesterday => '昨天编辑';

  @override
  String editedOn(String date) {
    return '$date编辑';
  }

  @override
  String get editedJustNow => '刚刚编辑';

  @override
  String editedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前编辑',
    );
    return '$_temp0';
  }

  @override
  String editedTodayAt(String time) {
    return '今天 $time 编辑';
  }

  @override
  String editedYesterdayAt(String time) {
    return '昨天 $time 编辑';
  }

  @override
  String editedOnAt(String date, String time) {
    return '$date $time 编辑';
  }

  @override
  String trashRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这里的笔记将在 $count 天后删除。',
    );
    return '$_temp0';
  }

  @override
  String trashEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你删除的笔记会在这里保留 $count 天。',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '剩余 $count 天',
    );
    return '$_temp0';
  }

  @override
  String trashDeletesOn(String date) {
    return '将于 $date 删除。';
  }

  @override
  String trashDeletesAfter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将在 $count 天后删除。',
    );
    return '$_temp0';
  }

  @override
  String historyKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '笔记每次更改都会保存一个版本，保留 $count 天。',
    );
    return '$_temp0';
  }

  @override
  String historyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '超过 $count 天的编辑记录会被移除。',
    );
    return '$_temp0';
  }

  @override
  String get historyEarlier => '较早版本';

  @override
  String get historyNotSaved => '未保存';

  @override
  String get historyBeforeRestore => '恢复前';

  @override
  String get historySomeone => '某人';

  @override
  String get historyYou => '你';

  @override
  String get navNotes => '笔记';

  @override
  String get navArchive => '归档';

  @override
  String get navTrash => '废纸篓';

  @override
  String drawerAccount(String name) {
    return '$name，设置';
  }

  @override
  String shareNowCanView(String person) {
    return '$person 现在可以查看';
  }

  @override
  String shareNowCanEdit(String person) {
    return '$person 现在可以编辑';
  }

  @override
  String get revisionComparedCurrent => '与当前版本比较';

  @override
  String revisionComparedTodayAt(String time) {
    return '与今天 $time 的版本比较';
  }

  @override
  String revisionComparedYesterdayAt(String time) {
    return '与昨天 $time 的版本比较';
  }

  @override
  String revisionComparedOnAt(String date, String time) {
    return '与 $date $time 的版本比较';
  }

  @override
  String get listArchiveLine => '已从笔记中隐藏';

  @override
  String listTrashLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天后删除',
    );
    return '$_temp0';
  }

  @override
  String get listOfflineSaved => '离线 · 更改已保存在这台手机上';

  @override
  String listOfflineChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '离线 · $count 项更改待同步',
    );
    return '$_temp0';
  }

  @override
  String get listSyncFailed => '同步失败';

  @override
  String listTitleMenu(String title) {
    return '$title，打开菜单';
  }

  @override
  String get searchNotes => '搜索笔记';

  @override
  String get searchArchive => '搜索归档';

  @override
  String get searchTrash => '搜索废纸篓';

  @override
  String get actionTag => '标签';

  @override
  String get actionPin => '置顶';

  @override
  String get actionUnpin => '取消置顶';

  @override
  String get actionShare => '共享';

  @override
  String get actionHistory => '版本历史';

  @override
  String get actionUncheckAll => '取消全部勾选';

  @override
  String get actionDeleteChecked => '删除已勾选项目';

  @override
  String get actionArchive => '归档';

  @override
  String get actionUnarchive => '取消归档';

  @override
  String get actionDelete => '删除';

  @override
  String get actionRemove => '移除';

  @override
  String get actionRestore => '恢复';

  @override
  String get actionDeletePermanently => '永久删除';

  @override
  String notesPinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已置顶 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String notesUnpinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已取消置顶 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String notesArchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已归档 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String notesUnarchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已取消归档 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String itemsUnchecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已取消勾选 $count 个项目',
    );
    return '$_temp0';
  }

  @override
  String checkedItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已删除 $count 个已勾选项目',
    );
    return '$_temp0';
  }

  @override
  String notesRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已恢复 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String notesDeletedForever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已永久删除 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String notesMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已将 $count 条笔记移至废纸篓',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedFromYours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已从你的笔记中移除 $count 条笔记',
    );
    return '$_temp0';
  }

  @override
  String notesTrashedMixed(String moved, String removed) {
    return '$moved $removed';
  }

  @override
  String notesMovedToTrashPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已将 $count 条笔记移至废纸篓。',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已从你的笔记中移除 $count 条。',
    );
    return '$_temp0';
  }

  @override
  String get notesRemoveSharedTitle => '要从你的笔记中移除此笔记？';

  @override
  String get notesRemoveSharedMessage => '如需再次查看，需由所有者重新共享给你。';

  @override
  String notesDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '删除 $count 条笔记？',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteSharedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '与你共享的 $count 条笔记将从你的笔记中移除。如需再次查看，需由所有者重新共享给你。',
    );
    return '$_temp0';
  }

  @override
  String get notesDeleteForeverOneTitle => '永久删除此笔记？';

  @override
  String notesDeleteForeverTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '永久删除 $count 条笔记？',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteForeverMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此操作无法撤销。与你共享的人也将失去访问权限。',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyAction => '清空废纸篓';

  @override
  String get trashNothing => '没有可删除的内容';

  @override
  String get trashEmptyTitle => '清空废纸篓？';

  @override
  String trashEmptyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条笔记将被永久删除，此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptied => '废纸篓已清空';

  @override
  String get listViewOptions => '视图选项';

  @override
  String searchTag(String tag) {
    return '搜索 #$tag';
  }

  @override
  String searchNoResults(String query) {
    return '没有“$query”的结果';
  }

  @override
  String get searchNoResultsHelp => '请检查拼写，或换个关键词。';

  @override
  String get archiveEmptyTitle => '没有已归档的笔记';

  @override
  String get archiveEmptyHelp => '把想保留但不必每天查看的笔记归档。';

  @override
  String get trashEmptyStateTitle => '废纸篓是空的';

  @override
  String tagEmptyTitle(String tag) {
    return '没有带 #$tag 标签的笔记';
  }

  @override
  String get tagEmptyHelp => '你在这里新建的笔记会自动带上此标签。';

  @override
  String get notesLoading => '正在加载笔记';

  @override
  String get notesEmptyTitle => '还没有笔记';

  @override
  String get notesEmptyHelp => '点按“新建笔记”写下第一条。';

  @override
  String get notesLoadFailedTitle => '无法加载你的笔记';

  @override
  String get notesLoadFailedHelp => '请检查网络连接，然后重试。';

  @override
  String get notesLoadPausedHelp => '笔记同步后会显示在这里。';

  @override
  String get noteNew => '新建笔记';

  @override
  String get cardNotSynced => '尚未同步';

  @override
  String cardPictures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张图片',
    );
    return '$_temp0';
  }

  @override
  String shareSharedBy(String name) {
    return '由 $name 共享';
  }

  @override
  String get actionSharing => '共享';

  @override
  String get actionMoveToTrash => '移至废纸篓';

  @override
  String get actionRemoveFromMine => '从我的笔记中移除';

  @override
  String get readOnlyInTrash => '位于废纸篓。';

  @override
  String get readOnlyViewOnly => '仅可查看。';

  @override
  String get readOnlyOwnerEdits => '只有所有者可以编辑。';

  @override
  String readOnlySharedBy(String name) {
    return '由 $name 共享。';
  }

  @override
  String get noteArchived => '已归档';

  @override
  String get tagAdd => '添加标签';

  @override
  String tagRemoveNamed(String tag) {
    return '移除 $tag';
  }

  @override
  String get starterList => '列表';

  @override
  String get starterAttachment => '图片或音频';

  @override
  String get attachmentPictureDeleted => '图片已删除';

  @override
  String get attachmentVoiceDeleted => '语音笔记已删除';

  @override
  String get attachmentAddLabel => '添加图片或音频';

  @override
  String get attachmentAdd => '添加';

  @override
  String get pullOffline => '你处于离线状态，更改已保存在这台手机上。';

  @override
  String get pullSyncing => '正在同步…';

  @override
  String get pullUpToDate => '已是最新';

  @override
  String get pullFailed => '同步失败，你的更改已保存在这台手机上。';

  @override
  String get searchClear => '清除搜索';

  @override
  String get lineText => '正文';

  @override
  String get lineH1 => '标题 1';

  @override
  String get lineH2 => '标题 2';

  @override
  String get lineH3 => '标题 3';

  @override
  String get lineChecklist => '清单';

  @override
  String get lineBullet => '项目符号列表';

  @override
  String get lineNumbered => '编号列表';

  @override
  String get lineQuote => '引用';

  @override
  String get lineCode => '代码块';

  @override
  String get editorLink => '链接';

  @override
  String get slashWordsChecklist => 'todo to-do task checkbox list 待办 清单 勾选';

  @override
  String get slashWordsH1 => 'h1 title 标题 一级标题';

  @override
  String get slashWordsH2 => 'h2 subtitle subheading 副标题 二级标题';

  @override
  String get slashWordsH3 => 'h3 subheading 三级标题';

  @override
  String get slashWordsBullet => 'unordered ul dashes 无序列表 项目符号';

  @override
  String get slashWordsNumbered => 'ordered ol 有序列表 编号';

  @override
  String get slashWordsQuote => 'blockquote citation 引用 引文';

  @override
  String get slashWordsCode => 'pre snippet 代码 代码块';

  @override
  String get slashWordsText => 'paragraph plain normal body 正文 段落 普通文本';

  @override
  String get slashWordsLink => 'url web address 链接 网址';

  @override
  String get slashWordsAttachment =>
      'image img photo file voice recording attachment 图片 照片 文件 语音 录音 附件';

  @override
  String get barFormatting => '格式';

  @override
  String get barList => '列表';

  @override
  String get barSelected => '已选文字';

  @override
  String get barStyles => '文字样式';

  @override
  String get barColors => '高亮颜色';

  @override
  String get barLineStyles => '行样式';

  @override
  String get toolOutdent => '减少缩进';

  @override
  String get toolIndent => '增加缩进';

  @override
  String get toolBold => '粗体';

  @override
  String get toolItalic => '斜体';

  @override
  String get toolUnderline => '下划线';

  @override
  String get toolStrikethrough => '删除线';

  @override
  String get toolHighlight => '高亮';

  @override
  String get toolRemoveHighlight => '移除高亮';

  @override
  String get toolRedo => '重做';

  @override
  String get toolHideKeyboard => '收起键盘';

  @override
  String get editorEmptyItem => '空条目';

  @override
  String get editorLinkCopied => '链接已复制';

  @override
  String editorCheckedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已勾选项目',
    );
    return '$_temp0';
  }

  @override
  String get linkAdd => '添加链接';

  @override
  String get linkEdit => '编辑链接';

  @override
  String get linkTextHint => '文字';

  @override
  String get commonOpen => '打开';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonRemove => '移除';

  @override
  String get editorSlashHint => '输入 / 查看更多';

  @override
  String get editorPlaceholder => '开始书写';

  @override
  String get commonTryAgain => '重试';

  @override
  String get historyCurrent => '当前版本';

  @override
  String get historySavedOnPhone => '已保存在这台手机上';

  @override
  String get historyNoChanges => '没有更改';

  @override
  String get historyEmptyTitle => '还没有较早版本';

  @override
  String get historyFetchFailed => '无法检查其他设备上的版本。';

  @override
  String get historyOffline => '连接网络即可查看其他设备上的版本。';

  @override
  String diffAdded(int count) {
    return '$count 行新增';
  }

  @override
  String diffRemoved(int count) {
    return '$count 行删除';
  }

  @override
  String diffChanged(int count) {
    return '$count 行更改';
  }

  @override
  String diffLinesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新增 $count 行',
    );
    return '$_temp0';
  }

  @override
  String diffLinesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '删除 $count 行',
    );
    return '$_temp0';
  }

  @override
  String diffLinesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '更改 $count 行',
    );
    return '$_temp0';
  }

  @override
  String diffShowUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '显示 $count 行未更改内容',
    );
    return '$_temp0';
  }

  @override
  String diffUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行未更改',
    );
    return '$_temp0';
  }

  @override
  String get diffAddedMark => '新增：';

  @override
  String get diffRemovedMark => '删除：';

  @override
  String get diffChangedMark => '更改：';

  @override
  String get diffCheckedMark => '已勾选：';

  @override
  String get diffUncheckedMark => '未勾选：';

  @override
  String get diffRemovedTitle => '删除的标题：';

  @override
  String get diffAddedTitle => '新增的标题：';

  @override
  String get revisionNotSavedLead => '未保存。';

  @override
  String get revisionNotSavedText => '此编辑未保存，因为笔记已在其他设备上先被修改。请恢复此版本，或复制你需要的内容。';

  @override
  String get revisionAlreadyMatches => '笔记已与此版本相同';

  @override
  String get revisionRestoreFailed => '无法恢复此版本';

  @override
  String get revisionRestoring => '正在恢复…';

  @override
  String get revisionBackToList => '返回版本列表';

  @override
  String get revisionNewer => '更新的版本';

  @override
  String get revisionOlder => '更早的版本';

  @override
  String revisionPosition(int index, int count) {
    return '第 $index 个，共 $count 个';
  }

  @override
  String get revisionGone => '此版本已不可用。';

  @override
  String get revisionSameAsNext => '与后一个版本的文字相同。';

  @override
  String get revisionSameAsCurrent => '与当前版本的文字相同。';

  @override
  String get revisionEmpty => '此版本为空。';

  @override
  String shareFailed(String name) {
    return '无法与 $name 共享';
  }

  @override
  String shareAccessFor(String name) {
    return '$name 的访问权限';
  }

  @override
  String shareRevoked(String name) {
    return '$name 已失去访问权限';
  }

  @override
  String shareRevokeFailed(String name) {
    return '无法移除 $name 的访问权限';
  }

  @override
  String shareChangeFailed(String name) {
    return '无法更改 $name 的访问权限';
  }

  @override
  String get shareSubtitle => '你添加的人会在他们的列表中看到这条笔记。';

  @override
  String get shareOffline => '连接网络即可共享此笔记。';

  @override
  String get shareSearchHint => '按姓名或邮箱添加联系人';

  @override
  String get shareNoMatches => '没有找到任何人。只有在此服务器上拥有账户的人才能被添加。';

  @override
  String get shareRecent => '最近共享给';

  @override
  String get sharePeople => '联系人';

  @override
  String shareAddPerson(String name) {
    return '添加 $name';
  }

  @override
  String get shareWithAccess => '有访问权限的人';

  @override
  String shareYou(String name) {
    return '$name（你）';
  }

  @override
  String get shareOwner => '所有者';

  @override
  String shareChangeAccess(String permission, String name) {
    return '$permission。更改 $name 的访问权限';
  }

  @override
  String get commonOffline => '离线';

  @override
  String commonDeleteItem(String name) {
    return '删除 $name';
  }

  @override
  String commonPosition(int index, int count) {
    return '第 $index 个，共 $count 个';
  }

  @override
  String get addToNote => '添加到笔记';

  @override
  String get addAudioFormats => 'Anchor 支持 MP3、WAV、M4A、OGG 和 AAC 音频';

  @override
  String get addPhotoUnsupported => '无法添加此照片，请使用 JPEG 或 PNG 格式。';

  @override
  String get addMicDenied => '请在设置中允许麦克风权限以进行录音';

  @override
  String get addTakePhoto => '拍照';

  @override
  String get addChoosePhoto => '选择照片';

  @override
  String get addRecordAudio => '录制音频';

  @override
  String get addAudioFile => '音频文件';

  @override
  String get recordingTitle => '录音';

  @override
  String get recordingHelp => '正常说话即可。录音会在上传前保存在这台手机上。';

  @override
  String get recordingReviewTitle => '你的录音';

  @override
  String recordingReviewHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒。先听一遍，再决定保留还是重录。',
    );
    return '$_temp0';
  }

  @override
  String get recordingStoppedAtLimit => '已达到最长时长并停止。先听一遍，再决定保留还是重录。';

  @override
  String recordingElapsed(String time) {
    return '录音中，$time';
  }

  @override
  String get recordingStop => '停止';

  @override
  String get recordingDiscard => '丢弃';

  @override
  String get recordingAgain => '重录';

  @override
  String get voiceOffline => '恢复联网后将播放此语音笔记';

  @override
  String get voiceNote => '语音笔记';

  @override
  String get voiceLoadFailed => '无法加载';

  @override
  String get attachmentUploading => '正在上传…';

  @override
  String get attachmentUploadFailed => '无法上传';

  @override
  String voicePosition(String name) {
    return '$name 中的位置';
  }

  @override
  String get pictureAllowPhotos => '请在设置中允许访问照片以保存图片';

  @override
  String get pictureSaved => '已保存到照片';

  @override
  String get pictureSaveFailed => '无法保存图片';

  @override
  String get pictureOffline => '恢复联网后将显示此图片';

  @override
  String get pictureLoadFailed => '无法加载此图片';

  @override
  String get pictureSaveToPhotos => '保存到照片';

  @override
  String attachmentRetry(String name) {
    return '重试，$name';
  }

  @override
  String pictureOpen(String name) {
    return '$name，打开';
  }

  @override
  String get groupPinned => '已置顶';

  @override
  String get groupOthers => '其他';

  @override
  String get groupArchived => '已归档';

  @override
  String get noteBackground => '背景';

  @override
  String get notePattern => '图案';

  @override
  String get noteColorDefault => '默认';

  @override
  String get patternDots => '圆点';

  @override
  String get patternGrid => '网格';

  @override
  String get patternLines => '横线';

  @override
  String get patternWaves => '波浪';

  @override
  String get patternGroceries => '购物';

  @override
  String get patternMusic => '音乐';

  @override
  String get patternTravel => '旅行';

  @override
  String get patternCode => '代码';

  @override
  String get viewLayout => '布局';

  @override
  String get viewMasonry => '瀑布流';

  @override
  String get viewGrid => '网格';

  @override
  String get viewList => '列表';

  @override
  String get viewSortBy => '排序方式';

  @override
  String get viewDateEdited => '编辑日期';

  @override
  String get viewDateCreated => '创建日期';

  @override
  String get viewTitle => '标题';

  @override
  String get viewAtoZ => 'A 到 Z';

  @override
  String get viewZtoA => 'Z 到 A';

  @override
  String get viewNewestFirst => '最新优先';

  @override
  String get viewOldestFirst => '最早优先';

  @override
  String get noteUnsynced => '更改尚未同步';

  @override
  String get noteOnThisPhone => '仅在本机';

  @override
  String get noteGone => '此笔记已不可用';

  @override
  String get reminderRemoved => '提醒已移除';

  @override
  String get versionRestored => '版本已恢复';

  @override
  String get attachmentPictureAdded => '图片已添加';

  @override
  String get attachmentVoiceAdded => '语音笔记已添加';

  @override
  String get attachmentPictureAddedOffline => '图片已添加。恢复联网后将自动上传。';

  @override
  String get attachmentVoiceAddedOffline => '语音笔记已添加。恢复联网后将自动上传。';

  @override
  String get attachmentPictureAddFailed => '无法添加图片';

  @override
  String get attachmentVoiceAddFailed => '无法添加语音笔记';

  @override
  String get attachmentAudioAdded => '音频文件已添加';

  @override
  String get attachmentAudioAddedOffline => '音频文件已添加。恢复联网后将自动上传。';

  @override
  String get attachmentAudioAddFailed => '无法添加音频文件';

  @override
  String get attachmentTooBig => '无法添加超过 50 MB 的文件。';

  @override
  String get attachmentAudioDeleted => '音频文件已删除';

  @override
  String get audioFileOffline => '恢复联网后将播放此音频文件';

  @override
  String get noteTitleHint => '标题';

  @override
  String get viewOrder => '顺序';

  @override
  String get editorDragHint => '拖动可重新排序';

  @override
  String get slashMenuLabel => '插入';

  @override
  String get slashNoResults => '没有结果';

  @override
  String get noteColor => '颜色';

  @override
  String cardChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已完成 $count 项',
    );
    return '$_temp0';
  }

  @override
  String cardAllChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部 $count 项已完成',
    );
    return '$_temp0';
  }

  @override
  String get shareSheetTitle => '新建笔记';

  @override
  String shareTag(String name) {
    return '标签 $name';
  }

  @override
  String get shareSignIn => '登录 Anchor 以保存你共享的内容。';

  @override
  String get shareOpenApp => '打开 Anchor';

  @override
  String get shareNothing => '这里没有 Anchor 可以保存的内容。';

  @override
  String shareNotAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件无法添加。',
    );
    return '$_temp0';
  }

  @override
  String shareUnsupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件无法添加。Anchor 支持图片和音频。',
    );
    return '$_temp0';
  }

  @override
  String shareTooBig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件超过 50 MB，无法添加。',
    );
    return '$_temp0';
  }

  @override
  String get shareOverLimit => '仅添加前 20 个文件。';

  @override
  String shareRemoveItem(String name) {
    return '移除 $name';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'Anchor 筆記';

  @override
  String get commonBack => '返回';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '關閉';

  @override
  String get commonDone => '完成';

  @override
  String get commonMenu => '選單';

  @override
  String get commonCloseMenu => '關閉選單';

  @override
  String get commonShowPassword => '顯示密碼';

  @override
  String get commonHidePassword => '隱藏密碼';

  @override
  String get commonSelectedNotes => '已選筆記';

  @override
  String get commonPlay => '播放';

  @override
  String get commonPause => '暫停';

  @override
  String commonPlayItem(String name) {
    return '播放 $name';
  }

  @override
  String commonPauseItem(String name) {
    return '暫停 $name';
  }

  @override
  String commonSwitchOn(String label) {
    return '$label，已開啟';
  }

  @override
  String commonSwitchOff(String label) {
    return '$label，已關閉';
  }

  @override
  String get formOffline => '你目前離線。請連線網路後繼續。';

  @override
  String get linkInvalid => '連結無效';

  @override
  String get linkCantOpen => '無法開啟連結';

  @override
  String get densityDefault => '預設';

  @override
  String get densityCompact => '緊湊';

  @override
  String get noteFontSans => '無襯線';

  @override
  String get noteFontSerif => '襯線';

  @override
  String get noteFontMono => '等寬';

  @override
  String get textSizeSmall => '小';

  @override
  String get textSizeDefault => '預設';

  @override
  String get textSizeLarge => '大';

  @override
  String get errorOffline => '沒有網路連線。';

  @override
  String get errorTimeout => '伺服器回應逾時。';

  @override
  String get errorCertificate => '伺服器憑證不受信任。';

  @override
  String get errorCancelled => '請求已取消。';

  @override
  String get errorSignInAgain => '請重新登入後繼續。';

  @override
  String get errorForbidden => '你沒有執行此操作的權限。';

  @override
  String get errorNotFound => '找不到該項目。';

  @override
  String get errorIncompatible => '此應用程式與你的伺服器不相容，請更新後繼續。';

  @override
  String get errorCheckInput => '請檢查你填寫的資訊。';

  @override
  String get errorGeneric => '出了點問題，請重試。';

  @override
  String get errorServer => '伺服器出現問題，請稍後再試。';

  @override
  String get commonSave => '儲存';

  @override
  String get commonSaving => '正在儲存…';

  @override
  String get commonUndo => '復原';

  @override
  String get fieldName => '姓名';

  @override
  String get fieldNameHint => '你的名字';

  @override
  String get fieldEmail => '電子郵件';

  @override
  String get fieldEmailHint => 'you@example.com';

  @override
  String get fieldPassword => '密碼';

  @override
  String get fieldCurrentPassword => '目前密碼';

  @override
  String get fieldNewPassword => '新密碼';

  @override
  String passwordHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '至少 $count 個字元。',
    );
    return '$_temp0';
  }

  @override
  String get authEnterName => '請輸入你的名字。';

  @override
  String get authEnterEmail => '請輸入你的電子郵件地址。';

  @override
  String get authEnterValidEmail => '請輸入有效的電子郵件地址。';

  @override
  String get authEnterPassword => '請輸入你的密碼。';

  @override
  String get authEnterCurrentPassword => '請輸入目前密碼。';

  @override
  String authPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '請至少使用 $count 個字元。',
    );
    return '$_temp0';
  }

  @override
  String get authIncorrectCredentials => '電子郵件或密碼不正確。';

  @override
  String get authPasswordless => '此帳號不使用密碼，請改用你的登入服務登入。';

  @override
  String get authPendingApproval => '你的帳號正在等待管理員核准。';

  @override
  String authPasswordSignInOff(String provider) {
    return '電子郵件和密碼登入已關閉，請使用 $provider 登入。';
  }

  @override
  String authPasswordSignUpOff(String provider) {
    return '電子郵件和密碼註冊已關閉，請使用 $provider 註冊。';
  }

  @override
  String get authPasswordSignInOffHere => '此伺服器已關閉電子郵件和密碼登入。';

  @override
  String get authPasswordSignUpOffHere => '此伺服器已關閉電子郵件和密碼註冊。';

  @override
  String get authRegistrationClosed => '此伺服器不接受新帳號。';

  @override
  String get authEmailTaken => '該電子郵件已註冊帳號。';

  @override
  String get authLastAdmin => '你是此伺服器唯一的管理員，請先將其他人設為管理員。';

  @override
  String get authWrongCurrentPassword => '目前密碼不正確。';

  @override
  String get authSamePassword => '新密碼必須與目前密碼不同。';

  @override
  String get authUnreachable => '無法連線你的伺服器，請檢查網路後重試。';

  @override
  String get authProviderNotSetUp => '此伺服器未設定登入服務。';

  @override
  String get authProviderFailed => '無法透過你的服務登入，請重試。';

  @override
  String authProviderFailedWith(String detail) {
    return '無法透過你的服務登入：$detail';
  }

  @override
  String get authSignIn => '登入';

  @override
  String get authSigningIn => '正在登入…';

  @override
  String authContinueWith(String provider) {
    return '使用 $provider 繼續';
  }

  @override
  String authOpeningProvider(String provider) {
    return '正在開啟 $provider…';
  }

  @override
  String get authWelcomeBack => '歡迎回來';

  @override
  String get authSignInToAnchor => '登入以繼續使用 Anchor。';

  @override
  String authSignInTo(String server) {
    return '登入 $server';
  }

  @override
  String get authOfflineSignIn => '你目前離線，請連線網路後登入。';

  @override
  String get authNewToAnchor => '第一次使用 Anchor？';

  @override
  String get authCreateAnAccount => '建立帳號';

  @override
  String get authOr => '或';

  @override
  String get authCreateAccount => '建立帳號';

  @override
  String get authCreatingAccount => '正在建立帳號…';

  @override
  String get authCreateYourAccount => '建立你的帳號';

  @override
  String get authApprovalNeeded => '新帳號需要管理員核准後才能登入。';

  @override
  String get authRegisterSubtitle => '開始紀錄你的想法。';

  @override
  String get authAlreadyHaveAccount => '已有帳號？';

  @override
  String authWelcomeName(String name) {
    return '歡迎使用 Anchor，$name';
  }

  @override
  String get authWaitingTitle => '等待核准';

  @override
  String get authWaitingMessage => '管理員核准你的帳號後即可登入。';

  @override
  String get authBackToSignIn => '返回登入';

  @override
  String get deleteAccountTitle => '刪除帳號';

  @override
  String get deleteAccountWarning => '此操作無法復原。';

  @override
  String get deleteAccountMessage =>
      '你的帳號、筆記、標籤、附件和提醒將從此伺服器永久刪除。你共享過的筆記將不再對其他人可用。';

  @override
  String get deleteAccountExport => '如需保留筆記副本，請先在網頁版的設定中匯出。';

  @override
  String get deleteAccountPasswordHelp => '請輸入密碼以確認。';

  @override
  String get deleteAccountConfirm => '刪除帳號';

  @override
  String get deleteAccountDeleting => '正在刪除…';

  @override
  String get deleteAccountDone => '帳號已刪除';

  @override
  String get deleteAccountOffline => '你目前離線，請連線網路後刪除帳號。';

  @override
  String get deleteAccountDialogTitle => '刪除你的帳號？';

  @override
  String get deleteAccountDialogMessage => '你的帳號和筆記將從此伺服器永久刪除。';

  @override
  String get passwordTitle => '密碼';

  @override
  String get passwordChange => '修改密碼';

  @override
  String get passwordChanging => '正在修改…';

  @override
  String get passwordChanged => '密碼已修改';

  @override
  String get passwordOffline => '你目前離線，請連線網路後修改密碼。';

  @override
  String get profileTitle => '個人資料';

  @override
  String get profileSaved => '個人資料已儲存';

  @override
  String get profileOffline => '你目前離線，請連線網路後修改個人資料。';

  @override
  String get profilePhoto => '頭像';

  @override
  String get profilePhotoVisible => '與你共享筆記的人可以看到。';

  @override
  String get profileTakePhoto => '拍照';

  @override
  String get profileChoosePhoto => '選擇照片';

  @override
  String get profileRemovePhoto => '移除照片';

  @override
  String get profilePhotoUpdated => '照片已更新';

  @override
  String get profilePhotoUpdateFailed => '無法更新你的照片';

  @override
  String get profilePhotoRemoved => '照片已移除';

  @override
  String get profilePhotoRemoveFailed => '無法移除你的照片';

  @override
  String get profileEmailAdminOnly => '只有管理員可以修改你的電子郵件。';

  @override
  String get profileChangePhoto => '更換頭像';

  @override
  String get commonContinue => '繼續';

  @override
  String commonExpandedItem(String label) {
    return '$label，已展開';
  }

  @override
  String commonCollapsedItem(String label) {
    return '$label，已摺疊';
  }

  @override
  String get serverTitle => '伺服器';

  @override
  String get serverWelcome => '歡迎使用 Anchor';

  @override
  String get serverSubtitle => '輸入你的伺服器地址以開始。';

  @override
  String get serverAddress => '伺服器地址';

  @override
  String get serverAddressHint => 'notes.example.com';

  @override
  String get serverConnecting => '正在連線…';

  @override
  String get serverAdvanced => '進階';

  @override
  String get serverSelfSigned => '允許自簽憑證';

  @override
  String get serverSelfSignedWarning => '僅用於你自行管理的伺服器，Anchor 無法驗證其身份。';

  @override
  String get serverCustomHeaders => '自訂標頭';

  @override
  String get serverCustomHeadersHint =>
      '隨每個請求傳送。用於伺服器前置的代理，例如 Cloudflare Access。';

  @override
  String get serverAddHeader => '新增標頭';

  @override
  String get serverRemoveHeader => '移除標頭';

  @override
  String serverRemoveNamedHeader(String name) {
    return '移除 $name';
  }

  @override
  String get serverHeaderRemoved => '標頭已移除';

  @override
  String get serverHeaderNameLabel => '標頭名稱';

  @override
  String get serverHeaderValueLabel => '標頭值';

  @override
  String get serverShowHeaderValue => '顯示值';

  @override
  String get serverHideHeaderValue => '隱藏值';

  @override
  String get serverHeaderNameHint => '名稱';

  @override
  String get serverHeaderValueHint => '值';

  @override
  String serverHeaderLimit(int max) {
    return '最多 $max 個標頭。';
  }

  @override
  String get serverHeaderMissingName => '請輸入標頭名稱。';

  @override
  String get serverHeaderInvalidName => '請輸入有效的標頭名稱。';

  @override
  String get serverHeaderInvalidValue => '請輸入有效的標頭值。';

  @override
  String get serverHeaderReserved => '此標頭由 Anchor 自行設定。';

  @override
  String get serverHeaderDuplicate => '此標頭已加入。';

  @override
  String get serverSelfHosted => 'Anchor 需要自託管伺服器。';

  @override
  String get serverEnterAddress => '請輸入伺服器地址。';

  @override
  String get serverEnterValidAddress => '請輸入有效的伺服器地址。';

  @override
  String get serverConnectFailed => '無法連線到伺服器，請重試。';

  @override
  String serverNotAnchor(String host) {
    return '$host 不是 Anchor 伺服器，請檢查地址。';
  }

  @override
  String serverUntrusted(String host) {
    return '無法驗證 $host 的憑證。如果是自簽憑證，請在“進階”中開啟“允許自簽憑證”。';
  }

  @override
  String serverUnreachableNoScheme(String host) {
    return '無法連線 $host。請檢查地址；如果你的伺服器不使用 https，請在地址前加上 http://。';
  }

  @override
  String serverUnreachable(String host) {
    return '無法連線 $host，請檢查地址和網路連線。';
  }

  @override
  String get serverConnectAnyway => '仍然連線';

  @override
  String serverLinkLabel(String host) {
    return '伺服器 $host。更換伺服器';
  }

  @override
  String get commonMore => '更多';

  @override
  String get commonCopy => '複製';

  @override
  String get commonSelect => '選擇';

  @override
  String get commonSelectAll => '全選';

  @override
  String get commonDeselectAll => '取消全選';

  @override
  String get commonStopSelecting => '結束選取';

  @override
  String commonSelectedCount(int count) {
    return '已選擇 $count 項';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String settingsProfileCard(String name, String email) {
    return '$name，$email。個人資料';
  }

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsDensity => '密度';

  @override
  String get settingsDensityHelp => '緊湊模式可在螢幕上顯示更多筆記。';

  @override
  String get settingsTheme => '主題';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAutomatic => '自動';

  @override
  String get settingsEditor => '編輯器';

  @override
  String get settingsFont => '字型';

  @override
  String get settingsTextSize => '文字大小';

  @override
  String get settingsMoveChecked => '將已勾選項目移至底部';

  @override
  String get settingsMoveCheckedHelp => '已勾選的條目會移到未勾選的條目下方。';

  @override
  String get settingsPreviewTitle => '里斯本週末';

  @override
  String get settingsPreviewText => '輕裝出行。山路陡峭，電車到九點就擠滿了。';

  @override
  String get settingsAccount => '帳號';

  @override
  String get settingsPassword => '密碼';

  @override
  String settingsPasswordManaged(String provider) {
    return '你的密碼由 $provider 管理。';
  }

  @override
  String get settingsPasswordManagedElsewhere => '你的密碼由登入服務管理。';

  @override
  String get settingsSignOut => '登出';

  @override
  String get settingsDeleteAccount => '刪除帳號';

  @override
  String get settingsSigningOut => '正在登出…';

  @override
  String get settingsSignOutTitle => '登出？';

  @override
  String settingsSignOutMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項更改尚未同步，它們會留在這支手機上，登入後再次同步。',
    );
    return '$_temp0';
  }

  @override
  String get settingsHelp => '幫助';

  @override
  String get settingsLogs => '日誌';

  @override
  String get settingsLogsHelp => '用於排查問題的活動詳情';

  @override
  String get settingsSupport => '支援 Anchor';

  @override
  String get settingsSupportHelp => '請開發者喝杯咖啡';

  @override
  String get settingsOffline => '離線。更改已儲存在這支手機上。';

  @override
  String settingsSyncPaused(String reason) {
    return '同步已暫停。$reason';
  }

  @override
  String settingsCantReach(String host) {
    return '無法連線 $host';
  }

  @override
  String settingsConnectedTo(String host) {
    return '已連線到 $host';
  }

  @override
  String settingsConnectedToVersion(String host, String version) {
    return '已連線到 $host · 伺服器 $version';
  }

  @override
  String settingsAppVersion(String version) {
    return 'Anchor $version';
  }

  @override
  String get settingsAppNameShort => 'Anchor';

  @override
  String get settingsTagline => '你的想法，安全儲存。';

  @override
  String get logsTitle => '日誌';

  @override
  String get logsMenuHelp => '複製和儲存也會包含更早的會話。';

  @override
  String get logsCopyAll => '全部複製';

  @override
  String get logsSaveToFile => '儲存到檔案';

  @override
  String get logsClear => '清除日誌';

  @override
  String get logsCopiedAll => '日誌已複製，包括更早的會話';

  @override
  String get logsCopiedNewest => '已複製最新的日誌。如需全部日誌，請儲存到檔案。';

  @override
  String get logsClearTitle => '清除日誌？';

  @override
  String get logsClearMessage => '這支手機上的所有日誌都將被刪除，此操作無法復原。';

  @override
  String get logsCleared => '日誌已清除';

  @override
  String get logsSaveDialog => '儲存日誌';

  @override
  String logsSaved(String name) {
    return '已儲存 $name';
  }

  @override
  String get logsSaveFailed => '無法儲存日誌';

  @override
  String logsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已複製 $count 則日誌',
    );
    return '$_temp0';
  }

  @override
  String get logsSelectTitle => '選擇日誌';

  @override
  String get logsSearch => '搜尋日誌';

  @override
  String get logsSelected => '已選日誌';

  @override
  String get logsLevel => '日誌級別';

  @override
  String get logsAll => '全部';

  @override
  String get logsErrors => '錯誤';

  @override
  String get logsWarnings => '警告';

  @override
  String get logsInfo => '資訊';

  @override
  String get logsDebug => '除錯';

  @override
  String get logsSessionNote => '僅顯示本次會話。複製和儲存也會包含更早的會話。';

  @override
  String get logsNoMatches => '沒有匹配的日誌';

  @override
  String get logsNoMatchesHelp => '換個關鍵字，或顯示所有級別。';

  @override
  String get logsEmpty => '還沒有日誌';

  @override
  String get logsEmptyHelp => '本次會話的活動會顯示在這裡。';

  @override
  String get logLevelError => '錯誤';

  @override
  String get logLevelWarning => '警告';

  @override
  String get logLevelInfo => '資訊';

  @override
  String get logLevelDebug => '除錯';

  @override
  String get commonToday => '今天';

  @override
  String get commonTomorrow => '明天';

  @override
  String get commonNotNow => '暫不';

  @override
  String get commonLater => '以後';

  @override
  String get commonOk => '好';

  @override
  String get commonOpenSettings => '開啟設定';

  @override
  String get reminderTitle => '提醒';

  @override
  String get reminderSheetSubtitle => '你會在這支手機上收到通知。';

  @override
  String reminderDayTime(String day, String time) {
    return '$day $time';
  }

  @override
  String reminderWithRepeat(String when, String repeat) {
    return '$when · $repeat';
  }

  @override
  String reminderSpoken(String when) {
    return '提醒：$when';
  }

  @override
  String reminderSpokenLate(String when) {
    return '已過期的提醒：$when';
  }

  @override
  String get reminderLaterToday => '今天晚些時候';

  @override
  String get reminderNextWeek => '下週';

  @override
  String get reminderNone => '無提醒';

  @override
  String get reminderPickTime => '選擇日期和時間';

  @override
  String get reminderTimePassed => '此時間已過';

  @override
  String reminderInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘後',
    );
    return '$_temp0';
  }

  @override
  String reminderInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時後',
    );
    return '$_temp0';
  }

  @override
  String reminderInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天後',
    );
    return '$_temp0';
  }

  @override
  String get reminderRepeatsDaily => '每天重複';

  @override
  String reminderRepeatsWeekly(String weekday) {
    return '每$weekday重複';
  }

  @override
  String reminderRepeatsMonthly(int day) {
    return '每月 $day 日重複';
  }

  @override
  String reminderRepeatsMonthlyEnd(int day) {
    return '每月 $day 日或月底重複';
  }

  @override
  String reminderRepeatsYearly(String date) {
    return '每年 $date 重複';
  }

  @override
  String get repeatOnce => '一次';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每週';

  @override
  String get repeatMonthly => '每月';

  @override
  String get repeatYearly => '每年';

  @override
  String get reminderWhen => '時間';

  @override
  String get reminderPickDate => '選擇日期';

  @override
  String get reminderDate => '日期';

  @override
  String get reminderTime => '時間';

  @override
  String get reminderRepeat => '重複';

  @override
  String get reminderRemove => '移除';

  @override
  String get reminderSetFailed => '無法設定提醒';

  @override
  String get reminderNotifyTitle => '允許通知？';

  @override
  String get reminderNotifyMessage => 'Anchor 需要通知權限，你的提醒才能在這支手機上響起。';

  @override
  String get reminderExactTitle => '允許精確鬧鐘？';

  @override
  String get reminderExactMessage => 'Android 可能會為省電而延遲提醒。請允許精確鬧鐘，讓提醒準時響起。';

  @override
  String get reminderNotificationsOff => '通知已關閉，請在手機設定中開啟。';

  @override
  String get monthPrevious => '上個月';

  @override
  String get monthNext => '下個月';

  @override
  String get reminderChannelName => '提醒';

  @override
  String get reminderChannelDescription => '你在筆記中設定的提醒';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => '標籤';

  @override
  String get tagNotesTitle => '為筆記加上標籤';

  @override
  String get tagSaveFailed => '無法儲存標籤';

  @override
  String get tagUpdateFailed => '無法更新標籤';

  @override
  String tagNameTaken(String name) {
    return '名為“$name”的標籤已存在。';
  }

  @override
  String tagCreateNamed(String name) {
    return '建立“$name”';
  }

  @override
  String tagAdded(String tag) {
    return '$tag，已加入';
  }

  @override
  String tagNotAdded(String tag) {
    return '$tag，未加入';
  }

  @override
  String tagAddedToSome(String tag) {
    return '$tag，已加入到部分筆記';
  }

  @override
  String get tagSearchOrCreate => '搜尋或建立標籤';

  @override
  String get tagsEmpty => '還沒有標籤。輸入名稱即可建立。';

  @override
  String tagSheetLabel(String name) {
    return '標籤 $name';
  }

  @override
  String get tagColor => '顏色';

  @override
  String get tagRename => '重新命名標籤';

  @override
  String get tagDelete => '刪除標籤';

  @override
  String tagDeleteTitle(String name) {
    return '刪除標籤“$name”？';
  }

  @override
  String tagDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '該標籤將從 $count 則筆記中移除，筆記本身不會被刪除。',
    );
    return '$_temp0';
  }

  @override
  String get tagDeleteUnused => '此標籤未用於任何筆記。';

  @override
  String tagDeleted(String name) {
    return '標籤“$name”已刪除';
  }

  @override
  String get tagNew => '新增標籤';

  @override
  String get tagNamePreview => '標籤名';

  @override
  String get tagNameHint => '標籤名稱';

  @override
  String get tagCreate => '建立標籤';

  @override
  String get tagRenameAction => '重新命名';

  @override
  String get colorRed => '紅色';

  @override
  String get colorPink => '粉色';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorDeepPurple => '深紫色';

  @override
  String get colorIndigo => '靛藍色';

  @override
  String get colorBlue => '藍色';

  @override
  String get colorLightBlue => '淺藍色';

  @override
  String get colorCyan => '青色';

  @override
  String get colorTeal => '藍綠色';

  @override
  String get colorGreen => '綠色';

  @override
  String get colorLightGreen => '淺綠色';

  @override
  String get colorLime => '黃綠色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorOrange => '橙色';

  @override
  String get colorDeepOrange => '深橙色';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorBlueGrey => '藍灰色';

  @override
  String get colorYellow => '黃色';

  @override
  String get syncSignedOutLead => '已登出。';

  @override
  String get syncSignedOutText => '請重新登入以同步筆記。';

  @override
  String get syncSignInAgainTitle => '重新登入';

  @override
  String get syncSignInAgainMessage => '你的筆記會留在這支手機上，登入後即可同步。';

  @override
  String get syncServerOutdatedLead => '請更新伺服器。';

  @override
  String get syncServerOutdatedText => '伺服器版本太舊，無法與此應用程式同步。';

  @override
  String get syncServerOutdatedTitle => '更新伺服器';

  @override
  String get syncServerOutdatedMessage =>
      '你的 Anchor 伺服器版本太舊，無法與此應用程式同步。請更新伺服器後繼續。';

  @override
  String get syncAppOutdatedLead => '請更新 Anchor。';

  @override
  String get syncAppOutdatedText => '此應用程式版本太舊，無法與你的伺服器同步。';

  @override
  String get syncAppOutdatedTitle => '更新 Anchor';

  @override
  String get syncAppOutdatedMessage =>
      '此應用程式版本太舊，無法與你的 Anchor 伺服器同步。請更新應用程式後繼續。';

  @override
  String syncPausedMessage(String reason) {
    return '$reason 在此期間，你的筆記會留在這支手機上。';
  }

  @override
  String get reminderAdd => '新增提醒';

  @override
  String get commonYesterday => '昨天';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人',
    );
    return '$_temp0';
  }

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個詞',
    );
    return '$_temp0';
  }

  @override
  String get notesSelectTitle => '選擇筆記';

  @override
  String get noteUntitled => '無標題';

  @override
  String namesTwo(String first, String second) {
    return '$first 和 $second';
  }

  @override
  String namesMore(String first, String second, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$first、$second 以及另外 $count 人',
    );
    return '$_temp0';
  }

  @override
  String get shareOnlyYou => '只有你可以看到這則筆記。';

  @override
  String get shareLoadFailed => '無法載入有存取權限的人。';

  @override
  String shareSharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已共享給 $count 人。',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已共享給 $count 人。連線網路後可檢視具體是誰。',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithNames(String names) {
    return '已共享給 $names';
  }

  @override
  String shareSharedWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已共享給 $count 人',
    );
    return '$_temp0';
  }

  @override
  String get shareCanView => '可檢視';

  @override
  String get shareCanEdit => '可編輯';

  @override
  String dayTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String dayYesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String dayOnAt(String date, String time) {
    return '$date $time';
  }

  @override
  String get editedToday => '今天編輯';

  @override
  String get editedYesterday => '昨天編輯';

  @override
  String editedOn(String date) {
    return '$date編輯';
  }

  @override
  String get editedJustNow => '剛剛編輯';

  @override
  String editedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘前編輯',
    );
    return '$_temp0';
  }

  @override
  String editedTodayAt(String time) {
    return '今天 $time 編輯';
  }

  @override
  String editedYesterdayAt(String time) {
    return '昨天 $time 編輯';
  }

  @override
  String editedOnAt(String date, String time) {
    return '$date $time 編輯';
  }

  @override
  String trashRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '這裡的筆記將在 $count 天後刪除。',
    );
    return '$_temp0';
  }

  @override
  String trashEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你刪除的筆記會在這裡保留 $count 天。',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '剩餘 $count 天',
    );
    return '$_temp0';
  }

  @override
  String trashDeletesOn(String date) {
    return '將於 $date 刪除。';
  }

  @override
  String trashDeletesAfter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '將在 $count 天後刪除。',
    );
    return '$_temp0';
  }

  @override
  String historyKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '筆記每次更改都會儲存一個版本，保留 $count 天。',
    );
    return '$_temp0';
  }

  @override
  String historyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '超過 $count 天的編輯紀錄會被移除。',
    );
    return '$_temp0';
  }

  @override
  String get historyEarlier => '較早版本';

  @override
  String get historyNotSaved => '未儲存';

  @override
  String get historyBeforeRestore => '還原前';

  @override
  String get historySomeone => '某人';

  @override
  String get historyYou => '你';

  @override
  String get navNotes => '筆記';

  @override
  String get navArchive => '封存';

  @override
  String get navTrash => '垃圾桶';

  @override
  String drawerAccount(String name) {
    return '$name，設定';
  }

  @override
  String shareNowCanView(String person) {
    return '$person 現在可以檢視';
  }

  @override
  String shareNowCanEdit(String person) {
    return '$person 現在可以編輯';
  }

  @override
  String get revisionComparedCurrent => '與目前版本比較';

  @override
  String revisionComparedTodayAt(String time) {
    return '與今天 $time 的版本比較';
  }

  @override
  String revisionComparedYesterdayAt(String time) {
    return '與昨天 $time 的版本比較';
  }

  @override
  String revisionComparedOnAt(String date, String time) {
    return '與 $date $time 的版本比較';
  }

  @override
  String get listArchiveLine => '已從筆記中隱藏';

  @override
  String listTrashLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天後刪除',
    );
    return '$_temp0';
  }

  @override
  String get listOfflineSaved => '離線 · 更改已儲存在這支手機上';

  @override
  String listOfflineChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '離線 · $count 項更改待同步',
    );
    return '$_temp0';
  }

  @override
  String get listSyncFailed => '同步失敗';

  @override
  String listTitleMenu(String title) {
    return '$title，開啟選單';
  }

  @override
  String get searchNotes => '搜尋筆記';

  @override
  String get searchArchive => '搜尋封存';

  @override
  String get searchTrash => '搜尋垃圾桶';

  @override
  String get actionTag => '標籤';

  @override
  String get actionPin => '置頂';

  @override
  String get actionUnpin => '取消置頂';

  @override
  String get actionShare => '共享';

  @override
  String get actionHistory => '版本紀錄';

  @override
  String get actionUncheckAll => '取消全部勾選';

  @override
  String get actionDeleteChecked => '刪除已勾選項目';

  @override
  String get actionArchive => '封存';

  @override
  String get actionUnarchive => '取消封存';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionRemove => '移除';

  @override
  String get actionRestore => '還原';

  @override
  String get actionDeletePermanently => '永久刪除';

  @override
  String notesPinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已置頂 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String notesUnpinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已取消置頂 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String notesArchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已封存 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String notesUnarchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已取消封存 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String itemsUnchecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已取消勾選 $count 個項目',
    );
    return '$_temp0';
  }

  @override
  String checkedItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已刪除 $count 個已勾選項目',
    );
    return '$_temp0';
  }

  @override
  String notesRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已還原 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String notesDeletedForever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已永久刪除 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String notesMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已將 $count 則筆記移至垃圾桶',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedFromYours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已從你的筆記中移除 $count 則筆記',
    );
    return '$_temp0';
  }

  @override
  String notesTrashedMixed(String moved, String removed) {
    return '$moved $removed';
  }

  @override
  String notesMovedToTrashPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已將 $count 則筆記移至垃圾桶。',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已從你的筆記中移除 $count 條。',
    );
    return '$_temp0';
  }

  @override
  String get notesRemoveSharedTitle => '要從你的筆記中移除此筆記？';

  @override
  String get notesRemoveSharedMessage => '如需再次檢視，需由擁有者重新共享給你。';

  @override
  String notesDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '刪除 $count 則筆記？',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteSharedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '與你共享的 $count 則筆記將從你的筆記中移除。如需再次檢視，需由擁有者重新共享給你。',
    );
    return '$_temp0';
  }

  @override
  String get notesDeleteForeverOneTitle => '永久刪除此筆記？';

  @override
  String notesDeleteForeverTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '永久刪除 $count 則筆記？',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteForeverMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此操作無法復原。與你共享的人也將失去存取權限。',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyAction => '清空垃圾桶';

  @override
  String get trashNothing => '沒有可刪除的內容';

  @override
  String get trashEmptyTitle => '清空垃圾桶？';

  @override
  String trashEmptyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則筆記將被永久刪除，此操作無法復原。',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptied => '垃圾桶已清空';

  @override
  String get listViewOptions => '檢視選項';

  @override
  String searchTag(String tag) {
    return '搜尋 #$tag';
  }

  @override
  String searchNoResults(String query) {
    return '沒有“$query”的結果';
  }

  @override
  String get searchNoResultsHelp => '請檢查拼字，或換個關鍵字。';

  @override
  String get archiveEmptyTitle => '沒有已封存的筆記';

  @override
  String get archiveEmptyHelp => '把想保留但不必每天檢視的筆記封存。';

  @override
  String get trashEmptyStateTitle => '垃圾桶是空的';

  @override
  String tagEmptyTitle(String tag) {
    return '沒有帶 #$tag 標籤的筆記';
  }

  @override
  String get tagEmptyHelp => '你在這裡新增的筆記會自動帶上此標籤。';

  @override
  String get notesLoading => '正在載入筆記';

  @override
  String get notesEmptyTitle => '還沒有筆記';

  @override
  String get notesEmptyHelp => '點按“新增筆記”寫下第一則。';

  @override
  String get notesLoadFailedTitle => '無法載入你的筆記';

  @override
  String get notesLoadFailedHelp => '請檢查網路連線，然後重試。';

  @override
  String get notesLoadPausedHelp => '筆記同步後會顯示在這裡。';

  @override
  String get noteNew => '新增筆記';

  @override
  String get cardNotSynced => '尚未同步';

  @override
  String cardPictures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 張圖片',
    );
    return '$_temp0';
  }

  @override
  String shareSharedBy(String name) {
    return '由 $name 共享';
  }

  @override
  String get actionSharing => '共享';

  @override
  String get actionMoveToTrash => '移至垃圾桶';

  @override
  String get actionRemoveFromMine => '從我的筆記中移除';

  @override
  String get readOnlyInTrash => '位於垃圾桶。';

  @override
  String get readOnlyViewOnly => '僅可檢視。';

  @override
  String get readOnlyOwnerEdits => '只有擁有者可以編輯。';

  @override
  String readOnlySharedBy(String name) {
    return '由 $name 共享。';
  }

  @override
  String get noteArchived => '已封存';

  @override
  String get tagAdd => '新增標籤';

  @override
  String tagRemoveNamed(String tag) {
    return '移除 $tag';
  }

  @override
  String get starterList => '清單';

  @override
  String get starterAttachment => '圖片或音訊';

  @override
  String get attachmentPictureDeleted => '圖片已刪除';

  @override
  String get attachmentVoiceDeleted => '語音筆記已刪除';

  @override
  String get attachmentAddLabel => '新增圖片或音訊';

  @override
  String get attachmentAdd => '新增';

  @override
  String get pullOffline => '你目前離線，更改已儲存在這支手機上。';

  @override
  String get pullSyncing => '正在同步…';

  @override
  String get pullUpToDate => '已是最新';

  @override
  String get pullFailed => '同步失敗，你的更改已儲存在這支手機上。';

  @override
  String get searchClear => '清除搜尋';

  @override
  String get lineText => '正文';

  @override
  String get lineH1 => '標題 1';

  @override
  String get lineH2 => '標題 2';

  @override
  String get lineH3 => '標題 3';

  @override
  String get lineChecklist => '清單';

  @override
  String get lineBullet => '項目符號清單';

  @override
  String get lineNumbered => '編號清單';

  @override
  String get lineQuote => '引用';

  @override
  String get lineCode => '程式碼區塊';

  @override
  String get editorLink => '連結';

  @override
  String get slashWordsChecklist => 'todo to-do task checkbox list 待辦 清單 勾選';

  @override
  String get slashWordsH1 => 'h1 title 標題 一級標題';

  @override
  String get slashWordsH2 => 'h2 subtitle subheading 副標題 二級標題';

  @override
  String get slashWordsH3 => 'h3 subheading 三級標題';

  @override
  String get slashWordsBullet => 'unordered ul dashes 無序清單 項目符號';

  @override
  String get slashWordsNumbered => 'ordered ol 有序清單 編號';

  @override
  String get slashWordsQuote => 'blockquote citation 引用 引文';

  @override
  String get slashWordsCode => 'pre snippet 程式碼 程式碼區塊';

  @override
  String get slashWordsText => 'paragraph plain normal body 正文 段落 普通文字';

  @override
  String get slashWordsLink => 'url web address 連結 網址';

  @override
  String get slashWordsAttachment =>
      'image img photo file voice recording attachment 圖片 照片 檔案 語音 錄音 附件';

  @override
  String get barFormatting => '格式';

  @override
  String get barList => '清單';

  @override
  String get barSelected => '已選文字';

  @override
  String get barStyles => '文字樣式';

  @override
  String get barColors => '醒目提示顏色';

  @override
  String get barLineStyles => '行樣式';

  @override
  String get toolOutdent => '減少縮排';

  @override
  String get toolIndent => '增加縮排';

  @override
  String get toolBold => '粗體';

  @override
  String get toolItalic => '斜體';

  @override
  String get toolUnderline => '底線';

  @override
  String get toolStrikethrough => '刪除線';

  @override
  String get toolHighlight => '醒目提示';

  @override
  String get toolRemoveHighlight => '移除醒目提示';

  @override
  String get toolRedo => '重做';

  @override
  String get toolHideKeyboard => '收起鍵盤';

  @override
  String get editorEmptyItem => '空條目';

  @override
  String get editorLinkCopied => '連結已複製';

  @override
  String editorCheckedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個已勾選項目',
    );
    return '$_temp0';
  }

  @override
  String get linkAdd => '新增連結';

  @override
  String get linkEdit => '編輯連結';

  @override
  String get linkTextHint => '文字';

  @override
  String get commonOpen => '開啟';

  @override
  String get commonEdit => '編輯';

  @override
  String get commonRemove => '移除';

  @override
  String get editorSlashHint => '輸入 / 檢視更多';

  @override
  String get editorPlaceholder => '開始書寫';

  @override
  String get commonTryAgain => '重試';

  @override
  String get historyCurrent => '目前版本';

  @override
  String get historySavedOnPhone => '已儲存在這支手機上';

  @override
  String get historyNoChanges => '沒有更改';

  @override
  String get historyEmptyTitle => '還沒有較早版本';

  @override
  String get historyFetchFailed => '無法檢查其他裝置上的版本。';

  @override
  String get historyOffline => '連線網路即可檢視其他裝置上的版本。';

  @override
  String diffAdded(int count) {
    return '$count 行新增';
  }

  @override
  String diffRemoved(int count) {
    return '$count 行刪除';
  }

  @override
  String diffChanged(int count) {
    return '$count 行更改';
  }

  @override
  String diffLinesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新增 $count 行',
    );
    return '$_temp0';
  }

  @override
  String diffLinesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '刪除 $count 行',
    );
    return '$_temp0';
  }

  @override
  String diffLinesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '更改 $count 行',
    );
    return '$_temp0';
  }

  @override
  String diffShowUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '顯示 $count 行未更改內容',
    );
    return '$_temp0';
  }

  @override
  String diffUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行未更改',
    );
    return '$_temp0';
  }

  @override
  String get diffAddedMark => '新增：';

  @override
  String get diffRemovedMark => '刪除：';

  @override
  String get diffChangedMark => '更改：';

  @override
  String get diffCheckedMark => '已勾選：';

  @override
  String get diffUncheckedMark => '未勾選：';

  @override
  String get diffRemovedTitle => '刪除的標題：';

  @override
  String get diffAddedTitle => '新增的標題：';

  @override
  String get revisionNotSavedLead => '未儲存。';

  @override
  String get revisionNotSavedText => '此編輯未儲存，因為筆記已在其他裝置上先被修改。請還原此版本，或複製你需要的內容。';

  @override
  String get revisionAlreadyMatches => '筆記已與此版本相同';

  @override
  String get revisionRestoreFailed => '無法還原此版本';

  @override
  String get revisionRestoring => '正在還原…';

  @override
  String get revisionBackToList => '返回版本清單';

  @override
  String get revisionNewer => '更新的版本';

  @override
  String get revisionOlder => '更早的版本';

  @override
  String revisionPosition(int index, int count) {
    return '第 $index 個，共 $count 個';
  }

  @override
  String get revisionGone => '此版本已不可用。';

  @override
  String get revisionSameAsNext => '與後一個版本的文字相同。';

  @override
  String get revisionSameAsCurrent => '與目前版本的文字相同。';

  @override
  String get revisionEmpty => '此版本為空。';

  @override
  String shareFailed(String name) {
    return '無法與 $name 共享';
  }

  @override
  String shareAccessFor(String name) {
    return '$name 的存取權限';
  }

  @override
  String shareRevoked(String name) {
    return '$name 已失去存取權限';
  }

  @override
  String shareRevokeFailed(String name) {
    return '無法移除 $name 的存取權限';
  }

  @override
  String shareChangeFailed(String name) {
    return '無法更改 $name 的存取權限';
  }

  @override
  String get shareSubtitle => '你新增的人會在他們的清單中看到這則筆記。';

  @override
  String get shareOffline => '連線網路即可共享此筆記。';

  @override
  String get shareSearchHint => '按姓名或電子郵件新增聯絡人';

  @override
  String get shareNoMatches => '沒有找到任何人。只有在此伺服器上擁有帳號的人才能被新增。';

  @override
  String get shareRecent => '最近共享給';

  @override
  String get sharePeople => '聯絡人';

  @override
  String shareAddPerson(String name) {
    return '新增 $name';
  }

  @override
  String get shareWithAccess => '有存取權限的人';

  @override
  String shareYou(String name) {
    return '$name（你）';
  }

  @override
  String get shareOwner => '擁有者';

  @override
  String shareChangeAccess(String permission, String name) {
    return '$permission。更改 $name 的存取權限';
  }

  @override
  String get commonOffline => '離線';

  @override
  String commonDeleteItem(String name) {
    return '刪除 $name';
  }

  @override
  String commonPosition(int index, int count) {
    return '第 $index 個，共 $count 個';
  }

  @override
  String get addToNote => '加入筆記';

  @override
  String get addAudioFormats => 'Anchor 支援 MP3、WAV、M4A、OGG 和 AAC 音訊';

  @override
  String get addPhotoUnsupported => '無法新增此照片，請使用 JPEG 或 PNG 格式。';

  @override
  String get addMicDenied => '請在設定中允許麥克風權限以進行錄音';

  @override
  String get addTakePhoto => '拍照';

  @override
  String get addChoosePhoto => '選擇照片';

  @override
  String get addRecordAudio => '錄製音訊';

  @override
  String get addAudioFile => '音訊檔案';

  @override
  String get recordingTitle => '錄音';

  @override
  String get recordingHelp => '正常說話即可。錄音會在上傳前儲存在這支手機上。';

  @override
  String get recordingReviewTitle => '你的錄音';

  @override
  String recordingReviewHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒。先聽一遍，再決定保留還是重錄。',
    );
    return '$_temp0';
  }

  @override
  String get recordingStoppedAtLimit => '已達到最長時長並停止。先聽一遍，再決定保留還是重錄。';

  @override
  String recordingElapsed(String time) {
    return '錄音中，$time';
  }

  @override
  String get recordingStop => '停止';

  @override
  String get recordingDiscard => '丟棄';

  @override
  String get recordingAgain => '重錄';

  @override
  String get voiceOffline => '重新連線後後將播放此語音筆記';

  @override
  String get voiceNote => '語音筆記';

  @override
  String get voiceLoadFailed => '無法載入';

  @override
  String get attachmentUploading => '正在上傳…';

  @override
  String get attachmentUploadFailed => '無法上傳';

  @override
  String voicePosition(String name) {
    return '$name 中的位置';
  }

  @override
  String get pictureAllowPhotos => '請在設定中允許訪問照片以儲存圖片';

  @override
  String get pictureSaved => '已儲存到照片';

  @override
  String get pictureSaveFailed => '無法儲存圖片';

  @override
  String get pictureOffline => '重新連線後後將顯示此圖片';

  @override
  String get pictureLoadFailed => '無法載入此圖片';

  @override
  String get pictureSaveToPhotos => '儲存到照片';

  @override
  String attachmentRetry(String name) {
    return '重試，$name';
  }

  @override
  String pictureOpen(String name) {
    return '$name，開啟';
  }

  @override
  String get groupPinned => '已置頂';

  @override
  String get groupOthers => '其他';

  @override
  String get groupArchived => '已封存';

  @override
  String get noteBackground => '背景';

  @override
  String get notePattern => '圖案';

  @override
  String get noteColorDefault => '預設';

  @override
  String get patternDots => '圓點';

  @override
  String get patternGrid => '網格';

  @override
  String get patternLines => '橫線';

  @override
  String get patternWaves => '波浪';

  @override
  String get patternGroceries => '購物';

  @override
  String get patternMusic => '音樂';

  @override
  String get patternTravel => '旅行';

  @override
  String get patternCode => '程式碼';

  @override
  String get viewLayout => '版面配置';

  @override
  String get viewMasonry => '瀑布流';

  @override
  String get viewGrid => '網格';

  @override
  String get viewList => '清單';

  @override
  String get viewSortBy => '排序方式';

  @override
  String get viewDateEdited => '編輯日期';

  @override
  String get viewDateCreated => '建立日期';

  @override
  String get viewTitle => '標題';

  @override
  String get viewAtoZ => 'A 到 Z';

  @override
  String get viewZtoA => 'Z 到 A';

  @override
  String get viewNewestFirst => '最新優先';

  @override
  String get viewOldestFirst => '最早優先';

  @override
  String get noteUnsynced => '更改尚未同步';

  @override
  String get noteOnThisPhone => '僅在本機';

  @override
  String get noteGone => '此筆記已不可用';

  @override
  String get reminderRemoved => '提醒已移除';

  @override
  String get versionRestored => '版本已還原';

  @override
  String get attachmentPictureAdded => '圖片已加入';

  @override
  String get attachmentVoiceAdded => '語音筆記已加入';

  @override
  String get attachmentPictureAddedOffline => '圖片已加入。重新連線後後將自動上傳。';

  @override
  String get attachmentVoiceAddedOffline => '語音筆記已加入。重新連線後後將自動上傳。';

  @override
  String get attachmentPictureAddFailed => '無法新增圖片';

  @override
  String get attachmentVoiceAddFailed => '無法新增語音筆記';

  @override
  String get attachmentAudioAdded => '音訊檔案已加入';

  @override
  String get attachmentAudioAddedOffline => '音訊檔案已加入。重新連線後後將自動上傳。';

  @override
  String get attachmentAudioAddFailed => '無法新增音訊檔案';

  @override
  String get attachmentTooBig => '無法新增超過 50 MB 的檔案。';

  @override
  String get attachmentAudioDeleted => '音訊檔案已刪除';

  @override
  String get audioFileOffline => '重新連線後後將播放此音訊檔案';

  @override
  String get noteTitleHint => '標題';

  @override
  String get viewOrder => '順序';

  @override
  String get editorDragHint => '拖曳可重新排序';

  @override
  String get slashMenuLabel => '插入';

  @override
  String get slashNoResults => '沒有結果';

  @override
  String get noteColor => '顏色';

  @override
  String cardChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已完成 $count 項',
    );
    return '$_temp0';
  }

  @override
  String cardAllChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '全部 $count 項已完成',
    );
    return '$_temp0';
  }

  @override
  String get shareSheetTitle => '新增筆記';

  @override
  String shareTag(String name) {
    return '標籤 $name';
  }

  @override
  String get shareSignIn => '登入 Anchor 以儲存你共享的內容。';

  @override
  String get shareOpenApp => '開啟 Anchor';

  @override
  String get shareNothing => '這裡沒有 Anchor 可以儲存的內容。';

  @override
  String shareNotAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案無法新增。',
    );
    return '$_temp0';
  }

  @override
  String shareUnsupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案無法新增。Anchor 支援圖片和音訊。',
    );
    return '$_temp0';
  }

  @override
  String shareTooBig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個檔案超過 50 MB，無法新增。',
    );
    return '$_temp0';
  }

  @override
  String get shareOverLimit => '僅新增前 20 個檔案。';

  @override
  String shareRemoveItem(String name) {
    return '移除 $name';
  }
}
