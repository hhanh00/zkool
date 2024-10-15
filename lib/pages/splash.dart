import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warp/warp.dart';

import '../../accounts.dart';
import '../init.dart';
import '../main.dart';
import 'utils.dart';
import '../appsettings.dart';
import '../coin/coins.dart';
import '../generated/intl/messages.dart';
import '../store.dart';

class SplashPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SplashState();
}

class _SplashState extends State<SplashPage> {
  late final s = S.of(context);
  final progressKey = GlobalKey<_LoadProgressState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future(() async {
        GetIt.I.registerSingleton<S>(S.of(context));
        if (!appSettings.hasMemo()) appSettings.memo = s.sendFrom(APP_NAME);
        _initProver();
        installQuickActions();
        // await _setupMempool();
        await initCoinDb();
        runMempool();
        await _restoreActive();
        // _initForegroundTask();
        _initBackgroundSync();
        _initAccel();
        final protectOpen = appSettings.protectOpen;
        if (protectOpen) {
          await authBarrier(context);
        }
        await requestNotificationPermissions();
        marketPrice.run();
        appStore.initialized = true;
        final startURL = launchURL;
        launchURL = null;
        GoRouter.of(context).go(startURL ?? '/account');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadProgress(key: progressKey);
  }

  // TODO
  // if (Platform.isWindows) {
  //   for (var c in coins) {
  //     registerProtocolHandler(c.currency, arguments: ['%s']);
  //   }
  // }

  void _initProver() async {
    _setProgress(0.1, 'Initialize ZK Prover');
    final spend = await rootBundle.load('assets/sapling-spend.params');
    final output = await rootBundle.load('assets/sapling-output.params');
    warp.initProver(spend.buffer.asUint8List(), output.buffer.asUint8List());
  }

  Future<void> initCoinDb() async {
    for (var c in coins) {
      final coin = c.coin;
      _setProgress(0.5 + 0.1 * coin, 'Initializing ${c.ticker}');
      final path = await upgradeDb(coin, appStore.dbPassword);
      logger.i("Db path: $path");
      warp.setDbPathPassword(coin, path, appStore.dbPassword);
      final cs = await CoinSettingsExtension.load(c.coin);
      warp.configure(coin,
          servers: cs.serversSelected,
          warp: cs.warpUrl,
          warpEndHeight: cs.warpHeight);
    }
    coinSettings = CoinSettingsExtension.load(0);
  }

  void runMempool() {
    for (var c in coins) {
      warp.mempoolRun(c.coin);
    }
  }

  Future<void> _restoreActive() async {
    _setProgress(0.8, 'Load Active Account');
    final prefs = GetIt.I.get<SharedPreferences>();
    final a = await ActiveAccount.fromPrefs(prefs);
    print('_restoreActive ${a?.id}');
    if (a != null) {
      await setActiveAccount(a.coin, a.id);
      await aa.update(MAXHEIGHT);
    } 
  }

  _initAccel() {
    if (isMobile()) accelerometerEvents.listen(handleAccel);
  }

  void _setProgress(double progress, String message) {
    print("$progress $message");
    progressKey.currentState!.setValue(progress, message);
  }

  _initBackgroundSync() {
    if (!isMobile()) return;

    // TODO Background sync
    // Workmanager().initialize(
    //   backgroundSyncDispatcher,
    // );
    // if (appSettings.backgroundSync != 0)
    //   Workmanager().registerPeriodicTask(
    //     'sync',
    //     'background-sync',
    //     constraints: Constraints(
    //       networkType: appSettings.backgroundSync == 1
    //           ? NetworkType.unmetered
    //           : NetworkType.connected,
    //     ),
    //   );
    // else
    //   Workmanager().cancelAll();
  }
}

class LoadProgress extends StatefulWidget {
  LoadProgress({Key? key}) : super(key: key);

  @override
  State<LoadProgress> createState() => _LoadProgressState();
}

class _LoadProgressState extends State<LoadProgress> {
  var _value = 0.0;
  String _message = "";

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = S.of(context);
    final textTheme = t.textTheme;
    return Scaffold(
        body: Container(
            alignment: Alignment.center,
            child: SizedBox(
                height: 240,
                width: 200,
                child: Column(children: [
                  Image.asset('assets/icon.png', height: 64),
                  Padding(padding: EdgeInsets.all(16)),
                  Text(s.loading, style: textTheme.headlineMedium),
                  Padding(padding: EdgeInsets.all(16)),
                  LinearProgressIndicator(value: _value),
                  Padding(padding: EdgeInsets.all(8)),
                  Text(_message, style: textTheme.labelMedium),
                ]))));
  }

  void setValue(double v, String message) {
    setState(() {
      _value = v;
      _message = message;
    });
  }
}

StreamSubscription? subUniLinks;

Future<bool> setActiveAccountOf(int coin) async {
  final coinSettings = await CoinSettingsExtension.load(coin);
  final id = coinSettings.account;
  if (id == 0) return false;
  await setActiveAccount(coin, id);
  return true;
}

void handleQuickAction(BuildContext context, String quickAction) {
  final t = quickAction.split(".");
  final coin = int.parse(t[0]);
  final shortcut = t[1];
  setActiveAccountOf(coin);
  switch (shortcut) {
    case 'receive':
      GoRouter.of(context).go('/account/pay_uri');
    case 'send':
      GoRouter.of(context).go('/account/quick_send');
  }
}

// @pragma('vm:entry-point')
// void backgroundSyncDispatcher() {
//   if (!appStore.initialized) return;
//   Workmanager().executeTask((task, inputData) async {
//     logger.i("Native called background task: $task");
//     await syncStatus.sync(false, auto: true);
//     return true;
//   });
// }
