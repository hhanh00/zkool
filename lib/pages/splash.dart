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

  Stream<ProgressMessage> load() async* {
    GetIt.I.registerSingleton<S>(S.of(context));
    if (!appSettings.hasMemo()) appSettings.memo = s.sendFrom(APP_NAME);
    yield (ProgressMessage(progress: 0.05, message: "Init Prover"));
    _initProver();
    yield (ProgressMessage(progress: 0.10, message: "Install Quick Action Handler"));
    installQuickActions();
    yield (ProgressMessage(progress: 0.20, message: "Connect to Db"));
    await initCoinDb();
    yield (ProgressMessage(progress: 0.30, message: "Run Mempool Monitor"));
    runMempool();
    yield (ProgressMessage(progress: 0.40, message: "Load Current Account"));
    await _restoreActive();
    yield (ProgressMessage(progress: 0.50, message: "Setup Background Sync"));
    // _initForegroundTask();
    _initBackgroundSync();
    yield (ProgressMessage(progress: 0.60, message: "Setup Accelerator Handler"));
    _initAccel();
    yield (ProgressMessage(progress: 0.70, message: "Open Lock Screen"));
    final protectOpen = appSettings.protectOpen;
    if (protectOpen) {
      await authBarrier(context);
    }
    yield (ProgressMessage(progress: 0.80, message: "Request Notification Permissions"));
    await requestNotificationPermissions();
    yield (ProgressMessage(progress: 0.90, message: "Get Market Price"));
    marketPrice.run();
    appStore.initialized = true;
    final startURL = launchURL;
    launchURL = null;
    yield (ProgressMessage(progress: 1.0, message: "Finished"));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(context).go(startURL ?? '/account');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgressMessage>(
      stream: load(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final pm = snapshot.data!;
          return LoadProgress(
            key: ValueKey(snapshot.data),
            pm.progress,
            pm.message,
          );
        }
        else if (snapshot.hasError) {
          showModalMessage(context, s.error, snapshot.error.toString());
        }
        return SizedBox.shrink();
      },
    );
  }

  // TODO
  // if (Platform.isWindows) {
  //   for (var c in coins) {
  //     registerProtocolHandler(c.currency, arguments: ['%s']);
  //   }
  // }

  void _initProver() async {
    final spend = await rootBundle.load('assets/sapling-spend.params');
    final output = await rootBundle.load('assets/sapling-output.params');
    warp.initProver(spend.buffer.asUint8List(), output.buffer.asUint8List());
  }

  Future<void> initCoinDb() async {
    for (var c in coins) {
      final coin = c.coin;
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
      final cs = CoinSettingsExtension.load(c.coin);
      if (cs.mempool) warp.mempoolRun(c.coin);
    }
  }

  Future<void> _restoreActive() async {
    final prefs = GetIt.I.get<SharedPreferences>();
    final a = await ActiveAccount.fromPrefs(prefs);
    if (a != null) {
      await setActiveAccount(a.coin, a.id);
      await aa.update(MAXHEIGHT);
    }
  }

  _initAccel() {
    if (isMobile()) accelerometerEventStream().listen(handleAccel);
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

class LoadProgress extends StatelessWidget {
  final double progress;
  final String message;
  LoadProgress(this.progress, this.message, {super.key});

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
                  LinearProgressIndicator(value: progress),
                  Padding(padding: EdgeInsets.all(8)),
                  Text(message, style: textTheme.labelMedium),
                ]))));
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
