// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Anchor Notes';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonMenu => 'Menü';

  @override
  String get commonCloseMenu => 'Menü schließen';

  @override
  String get commonShowPassword => 'Passwort anzeigen';

  @override
  String get commonHidePassword => 'Passwort ausblenden';

  @override
  String get commonSelectedNotes => 'Ausgewählte Notizen';

  @override
  String get commonPlay => 'Abspielen';

  @override
  String get commonPause => 'Pausieren';

  @override
  String commonPlayItem(String name) {
    return '$name abspielen';
  }

  @override
  String commonPauseItem(String name) {
    return '$name pausieren';
  }

  @override
  String commonSwitchOn(String label) {
    return '$label, ein';
  }

  @override
  String commonSwitchOff(String label) {
    return '$label, aus';
  }

  @override
  String get formOffline =>
      'Du bist offline. Verbinde dich mit dem Internet, um fortzufahren.';

  @override
  String get linkInvalid => 'Ungültiger Link';

  @override
  String get linkCantOpen => 'Der Link konnte nicht geöffnet werden';

  @override
  String get densityDefault => 'Standard';

  @override
  String get densityCompact => 'Kompakt';

  @override
  String get noteFontSans => 'Sans';

  @override
  String get noteFontSerif => 'Serif';

  @override
  String get noteFontMono => 'Mono';

  @override
  String get textSizeSmall => 'Klein';

  @override
  String get textSizeDefault => 'Standard';

  @override
  String get textSizeLarge => 'Groß';

  @override
  String get errorOffline => 'Keine Internetverbindung.';

  @override
  String get errorTimeout => 'Der Server hat nicht rechtzeitig geantwortet.';

  @override
  String get errorCertificate =>
      'Das Zertifikat des Servers ist nicht vertrauenswürdig.';

  @override
  String get errorCancelled => 'Die Anfrage wurde abgebrochen.';

  @override
  String get errorSignInAgain => 'Melde dich erneut an, um fortzufahren.';

  @override
  String get errorForbidden => 'Dazu hast du keine Berechtigung.';

  @override
  String get errorNotFound => 'Das Element wurde nicht gefunden.';

  @override
  String get errorIncompatible =>
      'Diese App und dein Server sind nicht kompatibel. Aktualisiere die App oder den Server, um fortzufahren.';

  @override
  String get errorCheckInput => 'Prüfe deine Eingaben.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Versuche es noch einmal.';

  @override
  String get errorServer =>
      'Auf dem Server ist ein Fehler aufgetreten. Versuche es später noch einmal.';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonSaving => 'Wird gespeichert …';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldNameHint => 'Dein Name';

  @override
  String get fieldEmail => 'E-Mail-Adresse';

  @override
  String get fieldEmailHint => 'name@example.com';

  @override
  String get fieldPassword => 'Passwort';

  @override
  String get fieldCurrentPassword => 'Aktuelles Passwort';

  @override
  String get fieldNewPassword => 'Neues Passwort';

  @override
  String passwordHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mindestens $count Zeichen.',
      one: 'Mindestens 1 Zeichen.',
    );
    return '$_temp0';
  }

  @override
  String get authEnterName => 'Gib deinen Namen ein.';

  @override
  String get authEnterEmail => 'Gib deine E-Mail-Adresse ein.';

  @override
  String get authEnterValidEmail => 'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get authEnterPassword => 'Gib dein Passwort ein.';

  @override
  String get authEnterCurrentPassword => 'Gib dein aktuelles Passwort ein.';

  @override
  String authPasswordTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Das Passwort muss mindestens $count Zeichen lang sein.',
      one: 'Das Passwort muss mindestens 1 Zeichen lang sein.',
    );
    return '$_temp0';
  }

  @override
  String get authIncorrectCredentials =>
      'E-Mail-Adresse oder Passwort ist falsch.';

  @override
  String get authPasswordless =>
      'Dieses Konto hat kein Passwort. Melde dich stattdessen über deinen Anmeldedienst an.';

  @override
  String get authPendingApproval =>
      'Dein Konto wurde noch nicht von einem Admin freigeschaltet.';

  @override
  String authPasswordSignInOff(String provider) {
    return 'Die Anmeldung mit E-Mail und Passwort ist deaktiviert. Melde dich mit $provider an.';
  }

  @override
  String authPasswordSignUpOff(String provider) {
    return 'Die Registrierung mit E-Mail und Passwort ist deaktiviert. Registriere dich mit $provider.';
  }

  @override
  String get authPasswordSignInOffHere =>
      'Die Anmeldung mit E-Mail und Passwort ist auf diesem Server deaktiviert.';

  @override
  String get authPasswordSignUpOffHere =>
      'Die Registrierung mit E-Mail und Passwort ist auf diesem Server deaktiviert.';

  @override
  String get authRegistrationClosed =>
      'Auf diesem Server können keine neuen Konten erstellt werden.';

  @override
  String get authEmailTaken =>
      'Es gibt bereits ein Konto mit dieser E-Mail-Adresse.';

  @override
  String get authLastAdmin =>
      'Außer dir gibt es auf diesem Server keinen Admin. Mach zuerst eine andere Person zum Admin.';

  @override
  String get authWrongCurrentPassword => 'Dein aktuelles Passwort ist falsch.';

  @override
  String get authSamePassword =>
      'Das neue Passwort muss sich vom aktuellen unterscheiden.';

  @override
  String get authUnreachable =>
      'Dein Server ist nicht erreichbar. Prüfe deine Verbindung und versuche es noch einmal.';

  @override
  String get authProviderNotSetUp =>
      'Auf diesem Server ist kein Anmeldedienst eingerichtet.';

  @override
  String get authProviderFailed =>
      'Die Anmeldung über deinen Anmeldedienst ist fehlgeschlagen. Versuche es noch einmal.';

  @override
  String authProviderFailedWith(String detail) {
    return 'Die Anmeldung über deinen Anmeldedienst ist fehlgeschlagen: $detail';
  }

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authSigningIn => 'Wird angemeldet …';

  @override
  String authContinueWith(String provider) {
    return 'Weiter mit $provider';
  }

  @override
  String authOpeningProvider(String provider) {
    return '$provider wird geöffnet …';
  }

  @override
  String get authWelcomeBack => 'Willkommen zurück';

  @override
  String get authSignInToAnchor => 'Melde dich an, um Anchor zu nutzen.';

  @override
  String authSignInTo(String server) {
    return 'Bei $server anmelden';
  }

  @override
  String get authOfflineSignIn =>
      'Du bist offline. Verbinde dich mit dem Internet, um dich anzumelden.';

  @override
  String get authNewToAnchor => 'Neu bei Anchor?';

  @override
  String get authCreateAnAccount => 'Konto erstellen';

  @override
  String get authOr => 'oder';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authCreatingAccount => 'Konto wird erstellt …';

  @override
  String get authCreateYourAccount => 'Erstelle dein Konto';

  @override
  String get authApprovalNeeded =>
      'Neue Konten müssen von einem Admin freigeschaltet werden, bevor du dich anmelden kannst.';

  @override
  String get authRegisterSubtitle => 'Halte deine Gedanken fest.';

  @override
  String get authAlreadyHaveAccount => 'Du hast schon ein Konto?';

  @override
  String authWelcomeName(String name) {
    return 'Willkommen bei Anchor, $name';
  }

  @override
  String get authWaitingTitle => 'Warten auf Freischaltung';

  @override
  String get authWaitingMessage =>
      'Ein Admin muss dein Konto freischalten, bevor du dich anmelden kannst.';

  @override
  String get authBackToSignIn => 'Zurück zur Anmeldung';

  @override
  String get deleteAccountTitle => 'Konto löschen';

  @override
  String get deleteAccountWarning => 'Das lässt sich nicht rückgängig machen.';

  @override
  String get deleteAccountMessage =>
      'Dein Konto, deine Notizen, Tags, Anhänge und Erinnerungen werden endgültig von diesem Server gelöscht. Notizen, die du geteilt hast, sind dann auch für andere nicht mehr verfügbar.';

  @override
  String get deleteAccountExport =>
      'Wenn du eine Kopie deiner Notizen behalten möchtest, exportiere sie vorher in den Einstellungen der Web-App.';

  @override
  String get deleteAccountPasswordHelp =>
      'Gib zur Bestätigung dein Passwort ein.';

  @override
  String get deleteAccountConfirm => 'Konto löschen';

  @override
  String get deleteAccountDeleting => 'Wird gelöscht …';

  @override
  String get deleteAccountDone => 'Konto gelöscht';

  @override
  String get deleteAccountOffline =>
      'Du bist offline. Verbinde dich mit dem Internet, um dein Konto zu löschen.';

  @override
  String get deleteAccountDialogTitle => 'Konto löschen?';

  @override
  String get deleteAccountDialogMessage =>
      'Dein Konto und deine Notizen werden endgültig von diesem Server gelöscht.';

  @override
  String get passwordTitle => 'Passwort';

  @override
  String get passwordChange => 'Passwort ändern';

  @override
  String get passwordChanging => 'Wird geändert …';

  @override
  String get passwordChanged => 'Passwort geändert';

  @override
  String get passwordOffline =>
      'Du bist offline. Verbinde dich mit dem Internet, um dein Passwort zu ändern.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSaved => 'Profil gespeichert';

  @override
  String get profileOffline =>
      'Du bist offline. Verbinde dich mit dem Internet, um dein Profil zu ändern.';

  @override
  String get profilePhoto => 'Profilbild';

  @override
  String get profilePhotoVisible =>
      'Personen, mit denen du Notizen teilst, können es sehen.';

  @override
  String get profileTakePhoto => 'Foto aufnehmen';

  @override
  String get profileChoosePhoto => 'Foto auswählen';

  @override
  String get profileRemovePhoto => 'Foto entfernen';

  @override
  String get profilePhotoUpdated => 'Foto aktualisiert';

  @override
  String get profilePhotoUpdateFailed =>
      'Foto konnte nicht aktualisiert werden';

  @override
  String get profilePhotoRemoved => 'Foto entfernt';

  @override
  String get profilePhotoRemoveFailed => 'Foto konnte nicht entfernt werden';

  @override
  String get profileEmailAdminOnly =>
      'Nur ein Admin kann deine E-Mail-Adresse ändern.';

  @override
  String get profileChangePhoto => 'Profilbild ändern';

  @override
  String get commonContinue => 'Weiter';

  @override
  String commonExpandedItem(String label) {
    return '$label, ausgeklappt';
  }

  @override
  String commonCollapsedItem(String label) {
    return '$label, eingeklappt';
  }

  @override
  String get serverTitle => 'Server';

  @override
  String get serverWelcome => 'Willkommen bei Anchor';

  @override
  String get serverSubtitle => 'Gib deine Serveradresse ein, um loszulegen.';

  @override
  String get serverAddress => 'Serveradresse';

  @override
  String get serverAddressHint => 'notes.example.com';

  @override
  String get serverConnecting => 'Wird verbunden …';

  @override
  String get serverAdvanced => 'Erweitert';

  @override
  String get serverSelfSigned => 'Selbstsignierte Zertifikate erlauben';

  @override
  String get serverSelfSignedWarning =>
      'Nur bei einem Server verwenden, den du selbst verwaltest. Anchor kann seine Identität nicht überprüfen.';

  @override
  String get serverCustomHeaders => 'Eigene Header';

  @override
  String get serverCustomHeadersHint =>
      'Werden bei jeder Anfrage mitgesendet. Für einen Proxy vor deinem Server, etwa Cloudflare Access.';

  @override
  String get serverAddHeader => 'Header hinzufügen';

  @override
  String get serverRemoveHeader => 'Header entfernen';

  @override
  String serverRemoveNamedHeader(String name) {
    return '$name entfernen';
  }

  @override
  String get serverHeaderRemoved => 'Header entfernt';

  @override
  String get serverHeaderNameLabel => 'Header-Name';

  @override
  String get serverHeaderValueLabel => 'Header-Wert';

  @override
  String get serverShowHeaderValue => 'Wert anzeigen';

  @override
  String get serverHideHeaderValue => 'Wert ausblenden';

  @override
  String get serverHeaderNameHint => 'Name';

  @override
  String get serverHeaderValueHint => 'Wert';

  @override
  String serverHeaderLimit(int max) {
    return 'Maximal $max Header.';
  }

  @override
  String get serverHeaderMissingName => 'Gib einen Header-Namen ein.';

  @override
  String get serverHeaderInvalidName => 'Gib einen gültigen Header-Namen ein.';

  @override
  String get serverHeaderInvalidValue => 'Gib einen gültigen Header-Wert ein.';

  @override
  String get serverHeaderReserved => 'Anchor setzt diesen Header selbst.';

  @override
  String get serverHeaderDuplicate => 'Dieser Header ist schon vorhanden.';

  @override
  String get serverSelfHosted =>
      'Anchor benötigt einen selbst gehosteten Server.';

  @override
  String get serverEnterAddress => 'Gib eine Serveradresse ein.';

  @override
  String get serverEnterValidAddress => 'Gib eine gültige Serveradresse ein.';

  @override
  String get serverConnectFailed =>
      'Die Verbindung zum Server konnte nicht hergestellt werden. Versuche es noch einmal.';

  @override
  String serverNotAnchor(String host) {
    return '$host ist kein Anchor-Server. Prüfe die Adresse.';
  }

  @override
  String serverUntrusted(String host) {
    return 'Das Zertifikat von $host konnte nicht überprüft werden. Wenn es selbstsigniert ist, aktiviere unter „Erweitert“ die Option „Selbstsignierte Zertifikate erlauben“.';
  }

  @override
  String serverUnreachableNoScheme(String host) {
    return '$host ist nicht erreichbar. Prüfe die Adresse oder ergänze http://, wenn dein Server kein https nutzt.';
  }

  @override
  String serverUnreachable(String host) {
    return '$host ist nicht erreichbar. Prüfe die Adresse und deine Verbindung.';
  }

  @override
  String get serverConnectAnyway => 'Trotzdem verbinden';

  @override
  String serverLinkLabel(String host) {
    return 'Server $host. Server wechseln';
  }

  @override
  String get commonMore => 'Mehr';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonSelect => 'Auswählen';

  @override
  String get commonSelectAll => 'Alle auswählen';

  @override
  String get commonDeselectAll => 'Auswahl aufheben';

  @override
  String get commonStopSelecting => 'Auswahl beenden';

  @override
  String commonSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String settingsProfileCard(String name, String email) {
    return '$name, $email. Profil';
  }

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsDensity => 'Anzeigedichte';

  @override
  String get settingsDensityHelp =>
      'Mit „Kompakt“ passen mehr Notizen auf den Bildschirm.';

  @override
  String get settingsTheme => 'Design';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeAutomatic => 'Automatisch';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsFont => 'Schriftart';

  @override
  String get settingsTextSize => 'Textgröße';

  @override
  String get settingsMoveChecked => 'Abgehakte Einträge nach unten verschieben';

  @override
  String get settingsMoveCheckedHelp =>
      'Abgehakte Einträge stehen dann unter den offenen.';

  @override
  String get settingsPreviewTitle => 'Wochenende in Lissabon';

  @override
  String get settingsPreviewText =>
      'Wenig Gepäck mitnehmen. Die Hügel sind steil und die Trams ab neun Uhr voll.';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsPassword => 'Passwort';

  @override
  String settingsPasswordManaged(String provider) {
    return 'Dein Passwort wird von $provider verwaltet.';
  }

  @override
  String get settingsPasswordManagedElsewhere =>
      'Dein Passwort wird von deinem Anmeldedienst verwaltet.';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsDeleteAccount => 'Konto löschen';

  @override
  String get settingsSigningOut => 'Wird abgemeldet …';

  @override
  String get settingsSignOutTitle => 'Abmelden?';

  @override
  String settingsSignOutMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Änderungen sind noch nicht synchronisiert, bleiben aber auf diesem Gerät und werden übertragen, sobald du dich wieder anmeldest.',
      one:
          '1 Änderung ist noch nicht synchronisiert, bleibt aber auf diesem Gerät und wird übertragen, sobald du dich wieder anmeldest.',
      zero:
          'Deine Notizen bleiben auf diesem Gerät und werden wieder synchronisiert, sobald du dich anmeldest.',
    );
    return '$_temp0';
  }

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsLogs => 'Protokolle';

  @override
  String get settingsLogsHelp => 'Details zur Fehlersuche';

  @override
  String get settingsSupport => 'Anchor unterstützen';

  @override
  String get settingsSupportHelp => 'Spendier dem Entwickler einen Kaffee';

  @override
  String get settingsOffline =>
      'Offline. Änderungen werden auf diesem Gerät gespeichert.';

  @override
  String settingsSyncPaused(String reason) {
    return 'Synchronisierung pausiert. $reason';
  }

  @override
  String settingsCantReach(String host) {
    return '$host nicht erreichbar';
  }

  @override
  String settingsConnectedTo(String host) {
    return 'Verbunden mit $host';
  }

  @override
  String settingsConnectedToVersion(String host, String version) {
    return 'Verbunden mit $host · Server $version';
  }

  @override
  String settingsAppVersion(String version) {
    return 'Anchor $version';
  }

  @override
  String get settingsAppNameShort => 'Anchor';

  @override
  String get settingsTagline => 'Deine Gedanken, sicher verwahrt.';

  @override
  String get logsTitle => 'Protokolle';

  @override
  String get logsMenuHelp =>
      'Beim Kopieren und Speichern sind auch frühere Sitzungen enthalten.';

  @override
  String get logsCopyAll => 'Alle kopieren';

  @override
  String get logsSaveToFile => 'Als Datei speichern';

  @override
  String get logsClear => 'Protokolle löschen';

  @override
  String get logsCopiedAll => 'Protokolle kopiert, auch aus früheren Sitzungen';

  @override
  String get logsCopiedNewest =>
      'Neueste Einträge kopiert. Mit „Als Datei speichern“ bekommst du alle.';

  @override
  String get logsClearTitle => 'Protokolle löschen?';

  @override
  String get logsClearMessage =>
      'Alle Protokolle auf diesem Gerät werden gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get logsCleared => 'Protokolle gelöscht';

  @override
  String get logsSaveDialog => 'Protokolle speichern';

  @override
  String logsSaved(String name) {
    return '$name gespeichert';
  }

  @override
  String get logsSaveFailed => 'Protokolle konnten nicht gespeichert werden';

  @override
  String logsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge kopiert',
      one: '1 Eintrag kopiert',
    );
    return '$_temp0';
  }

  @override
  String get logsSelectTitle => 'Einträge auswählen';

  @override
  String get logsSearch => 'Protokolle durchsuchen';

  @override
  String get logsSelected => 'Ausgewählte Einträge';

  @override
  String get logsLevel => 'Protokollebene';

  @override
  String get logsAll => 'Alle';

  @override
  String get logsErrors => 'Fehler';

  @override
  String get logsWarnings => 'Warnungen';

  @override
  String get logsInfo => 'Info';

  @override
  String get logsDebug => 'Debug';

  @override
  String get logsSessionNote =>
      'Nur diese Sitzung wird angezeigt. Beim Kopieren und Speichern sind auch frühere Sitzungen enthalten.';

  @override
  String get logsNoMatches => 'Keine passenden Einträge';

  @override
  String get logsNoMatchesHelp =>
      'Versuche es mit einem anderen Wort oder wähle „Alle“.';

  @override
  String get logsEmpty => 'Noch keine Einträge';

  @override
  String get logsEmptyHelp => 'Aktivitäten aus dieser Sitzung erscheinen hier.';

  @override
  String get logLevelError => 'Fehler';

  @override
  String get logLevelWarning => 'Warnung';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get logLevelDebug => 'Debug';

  @override
  String get commonToday => 'Heute';

  @override
  String get commonTomorrow => 'Morgen';

  @override
  String get commonNotNow => 'Nicht jetzt';

  @override
  String get commonLater => 'Später';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOpenSettings => 'Einstellungen öffnen';

  @override
  String get reminderTitle => 'Erinnerung';

  @override
  String get reminderSheetSubtitle =>
      'Du wirst auf diesem Gerät benachrichtigt.';

  @override
  String reminderDayTime(String day, String time) {
    return '$day, $time';
  }

  @override
  String reminderWithRepeat(String when, String repeat) {
    return '$when · $repeat';
  }

  @override
  String reminderSpoken(String when) {
    return 'Erinnerung: $when';
  }

  @override
  String reminderSpokenLate(String when) {
    return 'Überfällige Erinnerung: $when';
  }

  @override
  String get reminderLaterToday => 'Später am Tag';

  @override
  String get reminderNextWeek => 'Nächste Woche';

  @override
  String get reminderNone => 'Keine Erinnerung';

  @override
  String get reminderPickTime => 'Wähle Datum und Uhrzeit';

  @override
  String get reminderTimePassed => 'Dieser Zeitpunkt ist schon vorbei';

  @override
  String reminderInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Minuten',
      one: 'In einer Minute',
    );
    return '$_temp0';
  }

  @override
  String reminderInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Stunden',
      one: 'In einer Stunde',
    );
    return '$_temp0';
  }

  @override
  String reminderInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Tagen',
      one: 'In einem Tag',
    );
    return '$_temp0';
  }

  @override
  String get reminderRepeatsDaily => 'Jeden Tag';

  @override
  String reminderRepeatsWeekly(String weekday) {
    return 'Jeden $weekday';
  }

  @override
  String reminderRepeatsMonthly(int day) {
    return 'Jeden Monat am $day.';
  }

  @override
  String reminderRepeatsMonthlyEnd(int day) {
    return 'Jeden Monat am $day. oder am letzten Tag';
  }

  @override
  String reminderRepeatsYearly(String date) {
    return 'Jedes Jahr am $date';
  }

  @override
  String get repeatOnce => 'Einmalig';

  @override
  String get repeatDaily => 'Täglich';

  @override
  String get repeatWeekly => 'Wöchentlich';

  @override
  String get repeatMonthly => 'Monatlich';

  @override
  String get repeatYearly => 'Jährlich';

  @override
  String get reminderWhen => 'Zeitpunkt';

  @override
  String get reminderPickDate => 'Datum wählen';

  @override
  String get reminderDate => 'Datum';

  @override
  String get reminderTime => 'Uhrzeit';

  @override
  String get reminderRepeat => 'Wiederholen';

  @override
  String get reminderRemove => 'Entfernen';

  @override
  String get reminderSetFailed =>
      'Die Erinnerung konnte nicht gespeichert werden';

  @override
  String get reminderNotifyTitle => 'Benachrichtigungen erlauben?';

  @override
  String get reminderNotifyMessage =>
      'Damit du deine Erinnerungen auf diesem Gerät bekommst, braucht Anchor die Berechtigung für Benachrichtigungen.';

  @override
  String get reminderExactTitle => 'Wecker und Erinnerungen erlauben?';

  @override
  String get reminderExactMessage =>
      'Android kann Erinnerungen verzögern, um Akku zu sparen. Mit dieser Berechtigung kommen sie pünktlich.';

  @override
  String get reminderNotificationsOff =>
      'Benachrichtigungen sind deaktiviert. Aktiviere sie in den Einstellungen deines Geräts.';

  @override
  String get monthPrevious => 'Vorheriger Monat';

  @override
  String get monthNext => 'Nächster Monat';

  @override
  String get reminderChannelName => 'Erinnerungen';

  @override
  String get reminderChannelDescription => 'Erinnerungen für deine Notizen';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen',
      one: '1 Notiz',
    );
    return '$_temp0';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagNotesTitle => 'Tags hinzufügen';

  @override
  String get tagSaveFailed => 'Das Tag konnte nicht gespeichert werden';

  @override
  String get tagUpdateFailed => 'Die Tags konnten nicht aktualisiert werden';

  @override
  String tagNameTaken(String name) {
    return 'Es gibt schon ein Tag namens „$name“.';
  }

  @override
  String tagCreateNamed(String name) {
    return '„$name“ erstellen';
  }

  @override
  String tagAdded(String tag) {
    return '$tag, hinzugefügt';
  }

  @override
  String tagNotAdded(String tag) {
    return '$tag, nicht hinzugefügt';
  }

  @override
  String tagAddedToSome(String tag) {
    return '$tag, zu einigen Notizen hinzugefügt';
  }

  @override
  String get tagSearchOrCreate => 'Tag suchen oder erstellen';

  @override
  String get tagsEmpty =>
      'Noch keine Tags. Gib einen Namen ein, um ein neues zu erstellen.';

  @override
  String tagSheetLabel(String name) {
    return 'Tag $name';
  }

  @override
  String get tagColor => 'Farbe';

  @override
  String get tagRename => 'Tag umbenennen';

  @override
  String get tagDelete => 'Tag löschen';

  @override
  String tagDeleteTitle(String name) {
    return 'Tag „$name“ löschen?';
  }

  @override
  String tagDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Das Tag wird von $count Notizen entfernt. Die Notizen selbst bleiben erhalten.',
      one:
          'Das Tag wird von 1 Notiz entfernt. Die Notiz selbst bleibt erhalten.',
    );
    return '$_temp0';
  }

  @override
  String get tagDeleteUnused => 'Dieses Tag wird in keiner Notiz verwendet.';

  @override
  String tagDeleted(String name) {
    return 'Tag „$name“ gelöscht';
  }

  @override
  String get tagNew => 'Neues Tag';

  @override
  String get tagNamePreview => 'tagname';

  @override
  String get tagNameHint => 'Name des Tags';

  @override
  String get tagCreate => 'Tag erstellen';

  @override
  String get tagRenameAction => 'Umbenennen';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorPurple => 'Lila';

  @override
  String get colorDeepPurple => 'Violett';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorLightBlue => 'Hellblau';

  @override
  String get colorCyan => 'Türkis';

  @override
  String get colorTeal => 'Blaugrün';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorLightGreen => 'Hellgrün';

  @override
  String get colorLime => 'Gelbgrün';

  @override
  String get colorAmber => 'Goldgelb';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorDeepOrange => 'Rotorange';

  @override
  String get colorBrown => 'Braun';

  @override
  String get colorBlueGrey => 'Blaugrau';

  @override
  String get colorYellow => 'Gelb';

  @override
  String get syncSignedOutLead => 'Abgemeldet.';

  @override
  String get syncSignedOutText =>
      'Melde dich erneut an, um deine Notizen zu synchronisieren.';

  @override
  String get syncSignInAgainTitle => 'Erneut anmelden';

  @override
  String get syncSignInAgainMessage =>
      'Deine Notizen bleiben auf diesem Gerät und werden synchronisiert, sobald du dich anmeldest.';

  @override
  String get syncServerOutdatedLead => 'Aktualisiere deinen Server.';

  @override
  String get syncServerOutdatedText =>
      'Er ist zu alt, um mit dieser App zu synchronisieren.';

  @override
  String get syncServerOutdatedTitle => 'Server aktualisieren';

  @override
  String get syncServerOutdatedMessage =>
      'Dein Anchor-Server ist zu alt, um mit dieser App zu synchronisieren. Aktualisiere den Server, um fortzufahren.';

  @override
  String get syncAppOutdatedLead => 'Aktualisiere Anchor.';

  @override
  String get syncAppOutdatedText =>
      'Diese App ist zu alt, um mit deinem Server zu synchronisieren.';

  @override
  String get syncAppOutdatedTitle => 'Anchor aktualisieren';

  @override
  String get syncAppOutdatedMessage =>
      'Diese App ist zu alt, um mit deinem Anchor-Server zu synchronisieren. Aktualisiere die App, um fortzufahren.';

  @override
  String syncPausedMessage(String reason) {
    return '$reason Bis dahin bleiben deine Notizen auf diesem Gerät.';
  }

  @override
  String get reminderAdd => 'Erinnerung hinzufügen';

  @override
  String get commonYesterday => 'Gestern';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String wordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get notesSelectTitle => 'Notizen auswählen';

  @override
  String get noteUntitled => 'Ohne Titel';

  @override
  String namesTwo(String first, String second) {
    return '$first und $second';
  }

  @override
  String namesMore(String first, String second, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$first, $second und $count weiteren',
      one: '$first, $second und einer weiteren Person',
    );
    return '$_temp0';
  }

  @override
  String get shareOnlyYou => 'Nur du kannst diese Notiz sehen.';

  @override
  String get shareLoadFailed =>
      'Die Personen mit Zugriff konnten nicht geladen werden.';

  @override
  String shareSharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Geteilt mit $count Personen.',
      one: 'Geteilt mit 1 Person.',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Geteilt mit $count Personen. Stell eine Verbindung her, um zu sehen, wer Zugriff hat.',
      one:
          'Geteilt mit 1 Person. Stell eine Verbindung her, um zu sehen, wer Zugriff hat.',
    );
    return '$_temp0';
  }

  @override
  String shareSharedWithNames(String names) {
    return 'Geteilt mit $names';
  }

  @override
  String shareSharedWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Geteilt mit $count Personen',
      one: 'Geteilt mit 1 Person',
    );
    return '$_temp0';
  }

  @override
  String get shareCanView => 'Kann ansehen';

  @override
  String get shareCanEdit => 'Kann bearbeiten';

  @override
  String dayTodayAt(String time) {
    return 'Heute um $time';
  }

  @override
  String dayYesterdayAt(String time) {
    return 'Gestern um $time';
  }

  @override
  String dayOnAt(String date, String time) {
    return '$date um $time';
  }

  @override
  String get editedToday => 'Heute bearbeitet';

  @override
  String get editedYesterday => 'Gestern bearbeitet';

  @override
  String editedOn(String date) {
    return 'Am $date bearbeitet';
  }

  @override
  String get editedJustNow => 'Gerade eben bearbeitet';

  @override
  String editedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Min. bearbeitet',
      one: 'Vor 1 Min. bearbeitet',
    );
    return '$_temp0';
  }

  @override
  String editedTodayAt(String time) {
    return 'Heute um $time bearbeitet';
  }

  @override
  String editedYesterdayAt(String time) {
    return 'Gestern um $time bearbeitet';
  }

  @override
  String editedOnAt(String date, String time) {
    return 'Am $date um $time bearbeitet';
  }

  @override
  String trashRule(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notizen werden hier nach $count Tagen gelöscht.',
      one: 'Notizen werden hier nach 1 Tag gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String trashEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gelöschte Notizen bleiben $count Tage hier.',
      one: 'Gelöschte Notizen bleiben 1 Tag hier.',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Tage',
      one: 'Noch 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String trashDeletesOn(String date) {
    return 'Wird am $date gelöscht.';
  }

  @override
  String trashDeletesAfter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wird nach $count Tagen gelöscht.',
      one: 'Wird nach 1 Tag gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String historyKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bei jeder Änderung an der Notiz wird eine Version gespeichert und $count Tage lang aufbewahrt.',
      one:
          'Bei jeder Änderung an der Notiz wird eine Version gespeichert und einen Tag lang aufbewahrt.',
    );
    return '$_temp0';
  }

  @override
  String historyLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Versionen werden nach $count Tagen gelöscht.',
      one: 'Versionen werden nach einem Tag gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String get historyEarlier => 'Frühere Version';

  @override
  String get historyNotSaved => 'Nicht gespeichert';

  @override
  String get historyBeforeRestore => 'Vor dem Wiederherstellen';

  @override
  String get historySomeone => 'Unbekannt';

  @override
  String get historyYou => 'Du';

  @override
  String get navNotes => 'Notizen';

  @override
  String get navArchive => 'Archiv';

  @override
  String get navTrash => 'Papierkorb';

  @override
  String drawerAccount(String name) {
    return '$name, Einstellungen';
  }

  @override
  String shareNowCanView(String person) {
    return '$person kann die Notiz jetzt ansehen';
  }

  @override
  String shareNowCanEdit(String person) {
    return '$person kann die Notiz jetzt bearbeiten';
  }

  @override
  String get revisionComparedCurrent => 'Verglichen mit der aktuellen Version';

  @override
  String revisionComparedTodayAt(String time) {
    return 'Verglichen mit der Version von heute um $time';
  }

  @override
  String revisionComparedYesterdayAt(String time) {
    return 'Verglichen mit der Version von gestern um $time';
  }

  @override
  String revisionComparedOnAt(String date, String time) {
    return 'Verglichen mit der Version vom $date um $time';
  }

  @override
  String get listArchiveLine => 'In „Notizen“ ausgeblendet';

  @override
  String listTrashLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nach $count Tagen endgültig gelöscht',
      one: 'Nach 1 Tag endgültig gelöscht',
    );
    return '$_temp0';
  }

  @override
  String get listOfflineSaved =>
      'Offline · Änderungen werden auf diesem Gerät gespeichert';

  @override
  String listOfflineChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offline · $count Änderungen ausstehend',
      one: 'Offline · 1 Änderung ausstehend',
    );
    return '$_temp0';
  }

  @override
  String get listSyncFailed => 'Synchronisierung fehlgeschlagen';

  @override
  String listTitleMenu(String title) {
    return '$title, Menü öffnen';
  }

  @override
  String get searchNotes => 'Notizen durchsuchen';

  @override
  String get searchArchive => 'Archiv durchsuchen';

  @override
  String get searchTrash => 'Papierkorb durchsuchen';

  @override
  String get actionTag => 'Tags';

  @override
  String get actionPin => 'Anheften';

  @override
  String get actionUnpin => 'Loslösen';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionHistory => 'Versionsverlauf';

  @override
  String get actionUncheckAll => 'Alle Haken entfernen';

  @override
  String get actionDeleteChecked => 'Abgehakte Einträge löschen';

  @override
  String get actionArchive => 'Archivieren';

  @override
  String get actionUnarchive => 'Aus dem Archiv holen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionRemove => 'Entfernen';

  @override
  String get actionRestore => 'Wiederherstellen';

  @override
  String get actionDeletePermanently => 'Endgültig löschen';

  @override
  String notesPinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen angeheftet',
      one: 'Notiz angeheftet',
    );
    return '$_temp0';
  }

  @override
  String notesUnpinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen losgelöst',
      one: 'Notiz losgelöst',
    );
    return '$_temp0';
  }

  @override
  String notesArchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen archiviert',
      one: 'Notiz archiviert',
    );
    return '$_temp0';
  }

  @override
  String notesUnarchived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen aus dem Archiv geholt',
      one: 'Notiz aus dem Archiv geholt',
    );
    return '$_temp0';
  }

  @override
  String itemsUnchecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Haken entfernt',
      one: 'Haken entfernt',
    );
    return '$_temp0';
  }

  @override
  String checkedItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abgehakte Einträge gelöscht',
      one: 'Abgehakter Eintrag gelöscht',
    );
    return '$_temp0';
  }

  @override
  String notesRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen wiederhergestellt',
      one: 'Notiz wiederhergestellt',
    );
    return '$_temp0';
  }

  @override
  String notesDeletedForever(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen endgültig gelöscht',
      one: 'Notiz endgültig gelöscht',
    );
    return '$_temp0';
  }

  @override
  String notesMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen in den Papierkorb verschoben',
      one: 'Notiz in den Papierkorb verschoben',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedFromYours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geteilte Notizen entfernt',
      one: 'Geteilte Notiz entfernt',
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
      other: '$count Notizen in den Papierkorb verschoben.',
      one: '1 Notiz in den Papierkorb verschoben.',
    );
    return '$_temp0';
  }

  @override
  String notesRemovedPart(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geteilte Notizen entfernt.',
      one: '1 geteilte Notiz entfernt.',
    );
    return '$_temp0';
  }

  @override
  String get notesRemoveSharedTitle => 'Geteilte Notiz entfernen?';

  @override
  String get notesRemoveSharedMessage =>
      'Du siehst sie erst wieder, wenn sie noch einmal mit dir geteilt wird.';

  @override
  String notesDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen löschen?',
      one: '1 Notiz löschen?',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteSharedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count mit dir geteilte Notizen werden aus deinen Notizen entfernt. Du siehst sie erst wieder, wenn sie noch einmal mit dir geteilt werden.',
      one:
          'Eine mit dir geteilte Notiz wird aus deinen Notizen entfernt. Du siehst sie erst wieder, wenn sie noch einmal mit dir geteilt wird.',
    );
    return '$_temp0';
  }

  @override
  String get notesDeleteForeverOneTitle => 'Notiz endgültig löschen?';

  @override
  String notesDeleteForeverTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen endgültig löschen?',
      one: '1 Notiz endgültig löschen?',
    );
    return '$_temp0';
  }

  @override
  String notesDeleteForeverMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Das lässt sich nicht rückgängig machen. Auch alle, mit denen du sie geteilt hast, verlieren den Zugriff.',
      one:
          'Das lässt sich nicht rückgängig machen. Auch alle, mit denen du sie geteilt hast, verlieren den Zugriff.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyAction => 'Papierkorb leeren';

  @override
  String get trashNothing => 'Nichts zu löschen';

  @override
  String get trashEmptyTitle => 'Papierkorb leeren?';

  @override
  String trashEmptyMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Notizen werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.',
      one:
          '1 Notiz wird endgültig gelöscht. Das lässt sich nicht rückgängig machen.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptied => 'Papierkorb geleert';

  @override
  String get listViewOptions => 'Ansichtsoptionen';

  @override
  String searchTag(String tag) {
    return '#$tag durchsuchen';
  }

  @override
  String searchNoResults(String query) {
    return 'Keine Ergebnisse für „$query“';
  }

  @override
  String get searchNoResultsHelp =>
      'Prüfe die Schreibweise oder versuche es mit anderen Begriffen.';

  @override
  String get archiveEmptyTitle => 'Keine archivierten Notizen';

  @override
  String get archiveEmptyHelp =>
      'Archiviere Notizen, die du behalten, aber nicht jeden Tag sehen möchtest.';

  @override
  String get trashEmptyStateTitle => 'Der Papierkorb ist leer';

  @override
  String tagEmptyTitle(String tag) {
    return 'Keine Notizen mit #$tag';
  }

  @override
  String get tagEmptyHelp =>
      'Neue Notizen, die du hier erstellst, bekommen dieses Tag.';

  @override
  String get notesLoading => 'Notizen werden geladen';

  @override
  String get notesEmptyTitle => 'Noch keine Notizen';

  @override
  String get notesEmptyHelp =>
      'Tippe auf „Neue Notiz“, um deine erste zu schreiben.';

  @override
  String get notesLoadFailedTitle => 'Notizen konnten nicht geladen werden';

  @override
  String get notesLoadFailedHelp =>
      'Prüfe deine Verbindung und versuche es noch einmal.';

  @override
  String get notesLoadPausedHelp =>
      'Deine Notizen erscheinen hier, sobald sie synchronisiert sind.';

  @override
  String get noteNew => 'Neue Notiz';

  @override
  String get cardNotSynced => 'Noch nicht synchronisiert';

  @override
  String cardPictures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '1 Bild',
    );
    return '$_temp0';
  }

  @override
  String shareSharedBy(String name) {
    return 'Geteilt von $name';
  }

  @override
  String get actionSharing => 'Geteilt';

  @override
  String get actionMoveToTrash => 'In den Papierkorb verschieben';

  @override
  String get actionRemoveFromMine => 'Aus meinen Notizen entfernen';

  @override
  String get readOnlyInTrash => 'Im Papierkorb.';

  @override
  String get readOnlyViewOnly => 'Nur zum Ansehen.';

  @override
  String get readOnlyOwnerEdits =>
      'Nur wer die Notiz geteilt hat, kann sie bearbeiten.';

  @override
  String readOnlySharedBy(String name) {
    return 'Geteilt von $name.';
  }

  @override
  String get noteArchived => 'Archiviert';

  @override
  String get tagAdd => 'Tag hinzufügen';

  @override
  String tagRemoveNamed(String tag) {
    return '$tag entfernen';
  }

  @override
  String get starterList => 'Liste';

  @override
  String get starterAttachment => 'Bild oder Audio';

  @override
  String get attachmentPictureDeleted => 'Bild gelöscht';

  @override
  String get attachmentVoiceDeleted => 'Sprachnotiz gelöscht';

  @override
  String get attachmentAddLabel => 'Bild oder Audio hinzufügen';

  @override
  String get attachmentAdd => 'Hinzufügen';

  @override
  String get pullOffline =>
      'Du bist offline. Deine Änderungen sind auf diesem Gerät gespeichert.';

  @override
  String get pullSyncing => 'Wird synchronisiert …';

  @override
  String get pullUpToDate => 'Auf dem neuesten Stand';

  @override
  String get pullFailed =>
      'Synchronisierung fehlgeschlagen. Deine Änderungen sind auf diesem Gerät gespeichert.';

  @override
  String get searchClear => 'Suche löschen';

  @override
  String get lineText => 'Text';

  @override
  String get lineH1 => 'Überschrift 1';

  @override
  String get lineH2 => 'Überschrift 2';

  @override
  String get lineH3 => 'Überschrift 3';

  @override
  String get lineChecklist => 'Checkliste';

  @override
  String get lineBullet => 'Aufzählung';

  @override
  String get lineNumbered => 'Nummerierte Liste';

  @override
  String get lineQuote => 'Zitat';

  @override
  String get lineCode => 'Codeblock';

  @override
  String get editorLink => 'Link';

  @override
  String get slashWordsChecklist =>
      'todo to-do task checkbox list aufgabe aufgaben häkchen kästchen abhaken erledigen liste';

  @override
  String get slashWordsH1 => 'h1 title titel hauptüberschrift';

  @override
  String get slashWordsH2 =>
      'h2 subtitle subheading untertitel zwischenüberschrift';

  @override
  String get slashWordsH3 => 'h3 subheading zwischenüberschrift';

  @override
  String get slashWordsBullet =>
      'unordered ul dashes aufzählungszeichen stichpunkte punkte striche liste';

  @override
  String get slashWordsNumbered =>
      'ordered ol nummeriert nummerierung nummern zahlen liste';

  @override
  String get slashWordsQuote => 'blockquote citation zitieren';

  @override
  String get slashWordsCode => 'pre snippet quellcode programmcode';

  @override
  String get slashWordsText =>
      'paragraph plain normal body absatz fließtext standard';

  @override
  String get slashWordsLink =>
      'url web address webadresse adresse internetadresse webseite verlinken';

  @override
  String get slashWordsAttachment =>
      'image img photo file voice recording attachment bild foto datei sprachnotiz aufnahme anhang audio';

  @override
  String get barFormatting => 'Formatierung';

  @override
  String get barList => 'Liste';

  @override
  String get barSelected => 'Ausgewählter Text';

  @override
  String get barStyles => 'Textstile';

  @override
  String get barColors => 'Hervorhebungsfarben';

  @override
  String get barLineStyles => 'Zeilenstile';

  @override
  String get toolOutdent => 'Einzug verkleinern';

  @override
  String get toolIndent => 'Einzug vergrößern';

  @override
  String get toolBold => 'Fett';

  @override
  String get toolItalic => 'Kursiv';

  @override
  String get toolUnderline => 'Unterstrichen';

  @override
  String get toolStrikethrough => 'Durchgestrichen';

  @override
  String get toolHighlight => 'Hervorheben';

  @override
  String get toolRemoveHighlight => 'Hervorhebung entfernen';

  @override
  String get toolRedo => 'Wiederholen';

  @override
  String get toolHideKeyboard => 'Tastatur ausblenden';

  @override
  String get editorEmptyItem => 'Leerer Eintrag';

  @override
  String get editorLinkCopied => 'Link kopiert';

  @override
  String editorCheckedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abgehakte Einträge',
      one: '1 abgehakter Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get linkAdd => 'Link hinzufügen';

  @override
  String get linkEdit => 'Link bearbeiten';

  @override
  String get linkTextHint => 'Text';

  @override
  String get commonOpen => 'Öffnen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get editorSlashHint => 'Tippe / für weitere Optionen';

  @override
  String get editorPlaceholder => 'Schreib los';

  @override
  String get commonTryAgain => 'Erneut versuchen';

  @override
  String get historyCurrent => 'Aktuelle Version';

  @override
  String get historySavedOnPhone => 'Auf diesem Gerät gespeichert';

  @override
  String get historyNoChanges => 'Keine Änderungen';

  @override
  String get historyEmptyTitle => 'Noch keine früheren Versionen';

  @override
  String get historyFetchFailed =>
      'Versionen von deinen anderen Geräten konnten nicht abgerufen werden.';

  @override
  String get historyOffline =>
      'Verbinde dich mit dem Internet, um Versionen von deinen anderen Geräten zu sehen.';

  @override
  String diffAdded(int count) {
    return '$count hinzugefügt';
  }

  @override
  String diffRemoved(int count) {
    return '$count entfernt';
  }

  @override
  String diffChanged(int count) {
    return '$count geändert';
  }

  @override
  String diffLinesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen hinzugefügt',
      one: '1 Zeile hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String diffLinesRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen entfernt',
      one: '1 Zeile entfernt',
    );
    return '$_temp0';
  }

  @override
  String diffLinesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen geändert',
      one: '1 Zeile geändert',
    );
    return '$_temp0';
  }

  @override
  String diffShowUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unveränderte Zeilen anzeigen',
      one: '1 unveränderte Zeile anzeigen',
    );
    return '$_temp0';
  }

  @override
  String diffUnchanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unveränderte Zeilen',
      one: '1 unveränderte Zeile',
    );
    return '$_temp0';
  }

  @override
  String get diffAddedMark => 'Hinzugefügt:';

  @override
  String get diffRemovedMark => 'Entfernt:';

  @override
  String get diffChangedMark => 'Geändert:';

  @override
  String get diffCheckedMark => 'Abgehakt:';

  @override
  String get diffUncheckedMark => 'Nicht abgehakt:';

  @override
  String get diffRemovedTitle => 'Alter Titel:';

  @override
  String get diffAddedTitle => 'Neuer Titel:';

  @override
  String get revisionNotSavedLead => 'Nicht gespeichert.';

  @override
  String get revisionNotSavedText =>
      'Diese Änderung wurde nicht gespeichert, weil die Notiz zuvor auf einem anderen Gerät geändert wurde. Stelle sie wieder her oder kopiere, was du brauchst.';

  @override
  String get revisionAlreadyMatches =>
      'Die Notiz entspricht bereits dieser Version';

  @override
  String get revisionRestoreFailed =>
      'Diese Version konnte nicht wiederhergestellt werden';

  @override
  String get revisionRestoring => 'Wird wiederhergestellt …';

  @override
  String get revisionBackToList => 'Zurück zur Versionsliste';

  @override
  String get revisionNewer => 'Neuere Version';

  @override
  String get revisionOlder => 'Ältere Version';

  @override
  String revisionPosition(int index, int count) {
    return '$index von $count';
  }

  @override
  String get revisionGone => 'Diese Version ist nicht mehr verfügbar.';

  @override
  String get revisionSameAsNext => 'Gleicher Text wie in der Version danach.';

  @override
  String get revisionSameAsCurrent =>
      'Gleicher Text wie in der aktuellen Version.';

  @override
  String get revisionEmpty => 'Diese Version ist leer.';

  @override
  String shareFailed(String name) {
    return 'Die Notiz konnte nicht mit $name geteilt werden';
  }

  @override
  String shareAccessFor(String name) {
    return 'Zugriff für $name';
  }

  @override
  String shareRevoked(String name) {
    return '$name hat keinen Zugriff mehr';
  }

  @override
  String shareRevokeFailed(String name) {
    return 'Der Zugriff für $name konnte nicht entfernt werden';
  }

  @override
  String shareChangeFailed(String name) {
    return 'Der Zugriff für $name konnte nicht geändert werden';
  }

  @override
  String get shareSubtitle =>
      'Personen, die du hinzufügst, sehen diese Notiz in ihrer Liste.';

  @override
  String get shareOffline =>
      'Verbinde dich mit dem Internet, um diese Notiz zu teilen.';

  @override
  String get shareSearchHint => 'Personen per Name oder E-Mail hinzufügen';

  @override
  String get shareNoMatches =>
      'Keine Treffer. Du kannst nur Personen hinzufügen, die ein Konto auf diesem Server haben.';

  @override
  String get shareRecent => 'Zuletzt geteilt mit';

  @override
  String get sharePeople => 'Personen';

  @override
  String shareAddPerson(String name) {
    return '$name hinzufügen';
  }

  @override
  String get shareWithAccess => 'Personen mit Zugriff';

  @override
  String shareYou(String name) {
    return '$name (du)';
  }

  @override
  String get shareOwner => 'Eigentümer';

  @override
  String shareChangeAccess(String permission, String name) {
    return '$permission. Zugriff für $name ändern';
  }

  @override
  String get commonOffline => 'Offline';

  @override
  String commonDeleteItem(String name) {
    return '$name löschen';
  }

  @override
  String commonPosition(int index, int count) {
    return '$index von $count';
  }

  @override
  String get addToNote => 'Zur Notiz hinzufügen';

  @override
  String get addAudioFormats =>
      'Anchor unterstützt die Audioformate MP3, WAV, M4A, OGG und AAC';

  @override
  String get addPhotoUnsupported =>
      'Dieses Foto konnte nicht hinzugefügt werden. Versuche es mit JPEG oder PNG.';

  @override
  String get addMicDenied =>
      'Erlaube in den Einstellungen den Mikrofonzugriff, um aufzunehmen';

  @override
  String get addTakePhoto => 'Foto aufnehmen';

  @override
  String get addChoosePhoto => 'Foto auswählen';

  @override
  String get addRecordAudio => 'Audio aufnehmen';

  @override
  String get addAudioFile => 'Audiodatei';

  @override
  String get recordingTitle => 'Aufnahme';

  @override
  String get recordingHelp =>
      'Sprich ganz normal. Die Aufnahme bleibt auf diesem Gerät, bis sie hochgeladen ist.';

  @override
  String get recordingReviewTitle => 'Deine Aufnahme';

  @override
  String recordingReviewHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Sekunden. Hör dir die Aufnahme an und speichere sie oder nimm sie neu auf.',
      one:
          '1 Sekunde. Hör dir die Aufnahme an und speichere sie oder nimm sie neu auf.',
    );
    return '$_temp0';
  }

  @override
  String get recordingStoppedAtLimit =>
      'Maximale Länge erreicht. Hör dir die Aufnahme an und speichere sie oder nimm sie neu auf.';

  @override
  String recordingElapsed(String time) {
    return 'Aufnahme läuft, $time';
  }

  @override
  String get recordingStop => 'Stopp';

  @override
  String get recordingDiscard => 'Verwerfen';

  @override
  String get recordingAgain => 'Noch mal';

  @override
  String get voiceOffline =>
      'Du kannst diese Sprachnotiz abspielen, sobald du wieder online bist';

  @override
  String get voiceNote => 'Sprachnotiz';

  @override
  String get voiceLoadFailed => 'Laden fehlgeschlagen';

  @override
  String get attachmentUploading => 'Wird hochgeladen …';

  @override
  String get attachmentUploadFailed => 'Hochladen fehlgeschlagen';

  @override
  String voicePosition(String name) {
    return 'Position in $name';
  }

  @override
  String get pictureAllowPhotos =>
      'Erlaube in den Einstellungen den Zugriff auf Fotos, um Bilder zu speichern';

  @override
  String get pictureSaved => 'In Fotos gespeichert';

  @override
  String get pictureSaveFailed => 'Bild konnte nicht gespeichert werden';

  @override
  String get pictureOffline =>
      'Dieses Bild wird angezeigt, sobald du wieder online bist';

  @override
  String get pictureLoadFailed => 'Dieses Bild konnte nicht geladen werden';

  @override
  String get pictureSaveToPhotos => 'In Fotos speichern';

  @override
  String attachmentRetry(String name) {
    return 'Erneut versuchen, $name';
  }

  @override
  String pictureOpen(String name) {
    return '$name, öffnen';
  }

  @override
  String get groupPinned => 'Angeheftet';

  @override
  String get groupOthers => 'Weitere';

  @override
  String get groupArchived => 'Archiviert';

  @override
  String get noteBackground => 'Hintergrund';

  @override
  String get notePattern => 'Muster';

  @override
  String get noteColorDefault => 'Standard';

  @override
  String get patternDots => 'Punkte';

  @override
  String get patternGrid => 'Karos';

  @override
  String get patternLines => 'Linien';

  @override
  String get patternWaves => 'Wellen';

  @override
  String get patternGroceries => 'Einkauf';

  @override
  String get patternMusic => 'Musik';

  @override
  String get patternTravel => 'Reisen';

  @override
  String get patternCode => 'Code';

  @override
  String get viewLayout => 'Layout';

  @override
  String get viewMasonry => 'Mosaik';

  @override
  String get viewGrid => 'Raster';

  @override
  String get viewList => 'Liste';

  @override
  String get viewSortBy => 'Sortieren nach';

  @override
  String get viewDateEdited => 'Bearbeitungsdatum';

  @override
  String get viewDateCreated => 'Erstellungsdatum';

  @override
  String get viewTitle => 'Titel';

  @override
  String get viewAtoZ => 'A bis Z';

  @override
  String get viewZtoA => 'Z bis A';

  @override
  String get viewNewestFirst => 'Neueste zuerst';

  @override
  String get viewOldestFirst => 'Älteste zuerst';

  @override
  String get noteUnsynced => 'Änderungen noch nicht synchronisiert';

  @override
  String get noteOnThisPhone => 'Auf diesem Gerät';

  @override
  String get noteGone => 'Diese Notiz ist nicht mehr verfügbar';

  @override
  String get reminderRemoved => 'Erinnerung entfernt';

  @override
  String get versionRestored => 'Version wiederhergestellt';

  @override
  String get attachmentPictureAdded => 'Bild hinzugefügt';

  @override
  String get attachmentVoiceAdded => 'Sprachnotiz hinzugefügt';

  @override
  String get attachmentPictureAddedOffline =>
      'Bild hinzugefügt. Wird hochgeladen, sobald du wieder online bist.';

  @override
  String get attachmentVoiceAddedOffline =>
      'Sprachnotiz hinzugefügt. Wird hochgeladen, sobald du wieder online bist.';

  @override
  String get attachmentPictureAddFailed =>
      'Das Bild konnte nicht hinzugefügt werden';

  @override
  String get attachmentVoiceAddFailed =>
      'Die Sprachnotiz konnte nicht hinzugefügt werden';

  @override
  String get attachmentAudioAdded => 'Audiodatei hinzugefügt';

  @override
  String get attachmentAudioAddedOffline =>
      'Audiodatei hinzugefügt. Wird hochgeladen, sobald du wieder online bist.';

  @override
  String get attachmentAudioAddFailed =>
      'Die Audiodatei konnte nicht hinzugefügt werden';

  @override
  String get attachmentTooBig =>
      'Dateien über 50 MB können nicht hinzugefügt werden.';

  @override
  String get attachmentAudioDeleted => 'Audiodatei gelöscht';

  @override
  String get audioFileOffline =>
      'Du kannst diese Audiodatei abspielen, sobald du wieder online bist';

  @override
  String get noteTitleHint => 'Titel';

  @override
  String get viewOrder => 'Reihenfolge';

  @override
  String get editorDragHint => 'Zum Verschieben ziehen';

  @override
  String get slashMenuLabel => 'Einfügen';

  @override
  String get slashNoResults => 'Keine Ergebnisse';

  @override
  String get noteColor => 'Farbe';

  @override
  String cardChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erledigt',
      one: '1 erledigt',
    );
    return '$_temp0';
  }

  @override
  String cardAllChecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count erledigt',
      one: '1 von 1 erledigt',
    );
    return '$_temp0';
  }

  @override
  String get shareSheetTitle => 'Neue Notiz';

  @override
  String shareTag(String name) {
    return 'Tag $name';
  }

  @override
  String get shareSignIn =>
      'Melde dich bei Anchor an, um geteilte Inhalte zu speichern.';

  @override
  String get shareOpenApp => 'Anchor öffnen';

  @override
  String get shareNothing =>
      'Hier ist nichts dabei, was Anchor speichern kann.';

  @override
  String shareNotAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien konnten nicht hinzugefügt werden.',
      one: '1 Datei konnte nicht hinzugefügt werden.',
    );
    return '$_temp0';
  }

  @override
  String shareUnsupported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Dateien können nicht hinzugefügt werden. Anchor unterstützt nur Bilder und Audiodateien.',
      one:
          '1 Datei kann nicht hinzugefügt werden. Anchor unterstützt nur Bilder und Audiodateien.',
    );
    return '$_temp0';
  }

  @override
  String shareTooBig(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Dateien sind größer als 50 MB und können nicht hinzugefügt werden.',
      one: '1 Datei ist größer als 50 MB und kann nicht hinzugefügt werden.',
    );
    return '$_temp0';
  }

  @override
  String get shareOverLimit => 'Nur die ersten 20 Dateien werden hinzugefügt.';

  @override
  String shareRemoveItem(String name) {
    return '$name entfernen';
  }

  @override
  String get nativeWidgetLabel => 'Notizen';

  @override
  String get nativeWidgetDescription =>
      'Sieh dir deine Notizen an und erstelle neue direkt vom Startbildschirm aus.';

  @override
  String get nativeWidgetNewNote => 'Neue Notiz';

  @override
  String get nativeWidgetEmpty =>
      'Noch keine Notizen.\nTippe auf +, um deine erste zu schreiben.';

  @override
  String get nativeWidgetSignedOut =>
      'Melde dich bei Anchor an,\num hier deine Notizen zu sehen.';

  @override
  String get nativeCameraUse =>
      'Anchor verwendet die Kamera, um Fotos für deine Notizen und dein Profilbild aufzunehmen.';

  @override
  String get nativeMicrophoneUse =>
      'Anchor verwendet das Mikrofon, um Sprachnotizen aufzunehmen.';

  @override
  String get nativePhotoLibraryUse =>
      'Anchor verwendet deine Fotomediathek, damit du Bilder zu Notizen hinzufügen und dein Profilbild auswählen kannst.';

  @override
  String get nativePhotoLibraryAddUse =>
      'Anchor speichert Bilder aus deinen Notizen in deiner Fotomediathek.';

  @override
  String get nativeMusicUse =>
      'Anchor verwendet deine Musikmediathek, um Audiodateien zu Notizen hinzuzufügen.';

  @override
  String get nativeLocalNetworkUse =>
      'Anchor verbindet sich mit deinem Server, wenn er sich in deinem lokalen Netzwerk befindet.';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageName => 'Deutsch';

  @override
  String get sentenceSeparator => '. ';

  @override
  String get listSeparator => ', ';

  @override
  String get detailSeparator => ' · ';
}
