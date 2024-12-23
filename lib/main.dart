import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warp/warp.dart';
import 'package:path/path.dart' as path;

import 'appsettings.dart';
import 'coin/coins.dart';
import 'generated/intl/messages.dart';
import 'main.reflectable.dart';
import './pages/utils.dart';

import 'init.dart';
import 'router.dart';
import 'store.dart';

const ZECUNIT = 100000000.0;
// ignore: non_constant_identifier_names
var ZECUNIT_DECIMAL = Decimal.parse('100000000');
const mZECUNIT = 100000;

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
final appLinks = AppLinks();
final QuickActions quickActions = const QuickActions();
String? launchURL;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  GetIt.I.registerSingleton(prefs);
  warp.setup();
  registerURLHandler();
  await registerQuickActions();
  initializeReflectable();
  await restoreWindow();
  initNotifications();
  await restoreAppSettings();
  await initDbPath();
  await deleteOldDb();
  await recoverDb();
  runApp(App());
}

Future<void> restoreAppSettings() async {
  final prefs = GetIt.I.get<SharedPreferences>();
  appSettings = AppSettingsExtension.load(prefs);
}

Future<void> deleteOldDb() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final buildNumber = packageInfo.buildNumber;
  if (buildNumber != appSettings.buildNumber) {
    final prefs = GetIt.I.get<SharedPreferences>();
    final dbDir = Directory(appStore.dbDir);
    for (var c in coins) {
      for (var f in dbDir.listSync()) {
        if (f.path.startsWith(c.dbRoot))
          f.deleteSync();
      }
    }
    dbDir.createSync();
    appSettings.buildNumber = buildNumber;
    await appSettings.save(prefs);
  }
}

Future<void> recoverDb() async {
  final prefs = GetIt.I.get<SharedPreferences>();
  final backupPath = prefs.getString('backup');
  if (backupPath == null) return;
  logger.i('Recovering $backupPath');
  final backupDir = Directory(backupPath);
  final dbDir = await getDbPath();
  for (var file in await backupDir.list().whereType<File>().toList()) {
    final name = path.relative(file.path, from: backupPath);
    await file.copySync(path.join(dbDir, name));
  }
  await prefs.remove('backup');
  await backupDir.delete(recursive: true);
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// TODO: SETUP for iOS/Mac/Linux/Win
void registerURLHandler() {
  appLinks.uriLinkStream.listen((Uri uri) {
    logger.d(uri);
    final quickActionURL =
        '/account/send?uri=${Uri.encodeComponent(uri.toString())}';
    if (appStore.initialized) {
      router.go(quickActionURL);
    } else {
      launchURL = quickActionURL;
    }
  });
}

Future<void> registerQuickActions() async {
  if (!isMobile()) return;
  final quickActions = QuickActions();
  await quickActions.initialize((quickActionURL) {
    logger.d(quickActionURL);
    if (appStore.initialized) {
      router.go(quickActionURL);
    } else {
      launchURL = quickActionURL;
    }
  });
}

void installQuickActions() {
  if (!isMobile()) return;
  List<ShortcutItem> shortcuts = [];
  final context = rootNavigatorKey.currentContext!;
  final s = S.of(context);
  for (var c in coins) {
    final ticker = c.ticker;
    shortcuts.add(ShortcutItem(
        type: '/account?coin=${c.coin}',
        localizedTitle: s.receive(ticker),
        icon: 'receive'));
    shortcuts.add(ShortcutItem(
        type: '/account/send?coin=${c.coin}',
        localizedTitle: s.sendCointicker(ticker),
        icon: 'send'));
  }
  quickActions.setShortcutItems(shortcuts);
}

Future<void> requestNotificationPermissions() async {
  if (!isMobile()) return;
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
}
