import 'dart:async';
import 'dart:math';

import 'package:ZKool/router.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobx/mobx.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';

import 'appsettings.dart';
import 'pages/utils.dart';
import 'accounts.dart';
import 'coin/coins.dart';
import 'generated/intl/messages.dart';
import 'settings.pb.dart';

part 'store.g.dart';
part 'store.freezed.dart';

var appStore = AppStore();

class AppStore = _AppStore with _$AppStore;

abstract class _AppStore with Store {
  int dbVersion = warp.getSchemaVersion();
  bool initialized = false;
  String dbDir = '';
  String dbPassword = '';

  @observable
  bool flat = false;
}

Timer? syncTimer;

var syncStatus = SyncStatus();

class SyncStatus = _SyncStatus with _$SyncStatus;

abstract class _SyncStatus with Store {
  int startSyncedHeight = 0;
  bool isRescan = false;
  ETA eta = ETA();

  @observable
  bool connected = true;

  @observable
  int syncedHeight = 0;

  @observable
  int? latestHeight;

  @observable
  DateTime? timestamp;

  @observable
  bool syncing = false;

  @observable
  bool paused = false;

  @observable
  int reloadSeqno = 0;

  @computed
  int get changed {
    connected;
    syncedHeight;
    latestHeight;
    syncing;
    paused;
    reloadSeqno;
    return DateTime.now().microsecondsSinceEpoch;
  }

  @computed
  int get expirationHeight => confirmHeight + 100;

  @action
  void reload() {
    reloadSeqno += 1;
  }

  bool get isSynced {
    final sh = syncedHeight;
    final lh = latestHeight;
    return lh != null && sh >= lh;
  }

  int get confirmHeight {
    final lh = latestHeight ?? syncedHeight;
    final ch = lh - appSettings.anchorOffset + 1;
    return max(ch, 0);
  }

  @action
  void reset() {
    isRescan = false;
    syncedHeight = warp.getSyncHeight(aa.coin);
    syncing = false;
    paused = false;
  }

  bool updating = false;
  bool failed = false;
  int syncInterval = 0;

  @action
  Future<void> _update() async {
    aa.updateUnconfirmedBalance();

    if (updating) return;
    try {
      updating = true;
      await updateBCHeight();
      await sync(false, auto: true);
      aa.updateDivisified();
      failed = false;
      syncInterval = 15; // normal interval
      if (!connected) aa.update(latestHeight!);
      connected = true;
    } catch (e) {
      if (!failed) {
        syncInterval = 5; // first retry
        failed = true;
      } else {
        syncInterval = (syncInterval * 1.2).toInt(); // exp backoff
      }
      if (syncInterval > 10)
        connected = false; // notify when we tried a few times
      logger.d('Retry in $syncInterval seconds');
    } finally {
      updating = false;
    }
    Timer(Duration(seconds: syncInterval), _update);
  }

  void runAutoSync() {
    Timer(Duration(seconds: syncInterval), _update);
  }

  @action
  Future<void> updateBCHeight() async {
    final lh = await warp.getBCHeightOrNull(aa.coin);
    if (lh != null) {
      aa.update(lh);
      latestHeight = lh;
    }
    syncedHeight = warp.getSyncHeight(aa.coin);
  }

  Future<void> syncToHeight(int coin, int endHeight, ETA eta) async {
    var height = warp.getSyncHeight(coin);
    while (height < endHeight) {
      if (aa.coin != coin) break;
      await WarpSync.synchronize(aa.coin, endHeight);
      height = warp.getSyncHeight(aa.coin);
      eta.checkpoint(height, DateTime.now());
      aa.update(height);
      runInAction(() {
        syncedHeight = height;
      });
    }
  }

  @action
  Future<void> sync(bool rescan, {bool auto = false}) async {
    if (paused) return;
    if (syncing) return;
    try {
      await updateBCHeight();
      final lh = latestHeight;
      if (lh == null) return;
      // don't auto sync more than 1 month of data
      if (!rescan && auto && lh - syncedHeight > 30 * 24 * 60 * 4 / 5) {
        paused = true;
        return;
      }
      if (isSynced) return;
      syncing = true;
      isRescan = rescan;
      WakelockPlus.enable();
      _updateSyncedHeight();
      startSyncedHeight = syncedHeight;

      int coin = aa.coin;
      int account = aa.id;
      eta.begin(lh);
      eta.checkpoint(syncedHeight, DateTime.now());
      final preBalance = warp.getBalance(coin, account, lh);
      // This may take a long time
      await syncToHeight(coin, confirmHeight, eta);
      await syncToHeight(coin, lh, eta);
      eta.end();

      if (!appSettings.nogetTx) {
        await warp.retrieveTransactionDetails(aa.coin);
      }
      contacts.fetchContacts();
      await aa.update(syncedHeight);
      if (aa.coin == coin && aa.id == account) {
        final lh = syncStatus.latestHeight!;
        final postBalance = warp.getBalance(coin, account, lh);
        final context = rootNavigatorKey.currentContext!;
        final S s = S.of(context);
        final ticker = coins[aa.coin].ticker;
        if (preBalance.total < postBalance.total) {
          final amount = amountToString(postBalance.total - preBalance.total);
          showLocalNotification(
            id: lh,
            title: s.incomingFunds,
            body: s.received(amount, ticker),
          );
        } else if (preBalance.total > postBalance.total) {
          final amount = amountToString(preBalance.total - postBalance.total);
          showLocalNotification(
            id: lh,
            title: s.paymentMade,
            body: s.spent(amount, ticker),
          );
        }
      }
    } on String catch (e) {
      logger.d(e);
      showSnackBar(e);
    } finally {
      syncing = false;
      eta.end();
      WakelockPlus.disable();
    }
  }

  @action
  void resetToHeight(int height) {
    warp.resetChain(aa.coin, height);
    _updateSyncedHeight();
    paused = true;
  }

  @action
  void setPause(bool v) {
    paused = v;
  }

  @action
  void setProgress(ProgressT progress) {
    syncedHeight = progress.height;
    if (progress.timestamp > 0)
      timestamp =
          DateTime.fromMillisecondsSinceEpoch(progress.timestamp * 1000);
    eta.checkpoint(syncedHeight, DateTime.now());
  }

  void _updateSyncedHeight() {
    syncedHeight = warp.getSyncHeight(aa.coin);
  }
}

class ETA {
  int endHeight = 0;
  ETACheckpoint? start;
  ETACheckpoint? prev;
  ETACheckpoint? current;

  void begin(int height) {
    end();
    endHeight = height;
  }

  void end() {
    start = null;
    prev = null;
    current = null;
  }

  void checkpoint(int height, DateTime timestamp) {
    prev = current;
    current = ETACheckpoint(height, timestamp);
    if (start == null) start = current;
  }

  @computed
  int? get remaining {
    return current?.let((c) => endHeight - c.height);
  }

  @computed
  String get timeRemaining {
    final defaultMsg = "Calculating ETA";
    final p = prev;
    final c = current;
    if (p == null || c == null) return defaultMsg;
    if (c.timestamp.millisecondsSinceEpoch ==
        p.timestamp.millisecondsSinceEpoch) return defaultMsg;
    final speed = (c.height - p.height) /
        (c.timestamp.millisecondsSinceEpoch -
            p.timestamp.millisecondsSinceEpoch);
    if (speed == 0) return defaultMsg;
    final eta = (endHeight - c.height) / speed;
    if (eta <= 0) return defaultMsg;
    final duration =
        Duration(milliseconds: eta.floor()).toString().split('.')[0];
    return "ETA: $duration";
  }

  @computed
  bool get running => start != null;

  @computed
  int? get progress {
    if (!running) return null;
    final sh = start!.height;
    final ch = current!.height;
    final total = endHeight - sh;
    final percent = total > 0 ? 100 * (ch - sh) ~/ total : 0;
    return percent;
  }
}

class ETACheckpoint {
  int height;
  DateTime timestamp;

  ETACheckpoint(this.height, this.timestamp);
}

var marketPrice = MarketPrice();

class MarketPrice = _MarketPrice with _$MarketPrice;

abstract class _MarketPrice with Store {
  int? coin;
  String? currency;
  String? fiat;

  @observable
  double? price;

  void updateNow() {
    _update();
  }

  Future<void> _update() async {
    final c = coins[aa.coin];
    if (coin != aa.coin ||
        currency != c.currency ||
        fiat != appSettings.currency) {
      coin = aa.coin;
      currency = c.currency;
      fiat = appSettings.currency;
      runInAction(() => price = null);
    }
    if (currency != null && fiat != null) {
      final p = await getFxRate(currency!, fiat!);
      runInAction(() => price = p);
    }
  }

  void run() {
    int interval = 0;
    bool failed = false;
    void tryUpdatePrice() async {
      try {
        await _update();
        failed = false;
        interval = 60;
      } on Exception {
        if (failed)
          interval = min((interval * 1.2).toInt(), 300);
        else
          interval = 10;
        failed = true;
      }
      Timer(Duration(seconds: interval), tryUpdatePrice);
    }

    Future(tryUpdatePrice);
  }
}

var contacts = ContactStore();

class ContactStore = _ContactStore with _$ContactStore;

abstract class _ContactStore with Store {
  @observable
  List<ContactCardT> contacts = [];

  void fetchContacts() async {
    final cs = await warp.listContacts(aa.coin);
    runInAction(() {
      contacts = cs;
    });
  }

  void add(ContactCardT c) {
    warp.addContact(aa.coin, c);
    fetchContacts();
  }

  @action
  void remove(ContactCardT c) {
    contacts.removeWhere((contact) => contact.id == c.id);
    warp.deleteContact(aa.coin, c.id);
    fetchContacts();
  }
}

class AccountBalanceSnapshot {
  final int coin;
  final int id;
  final int balance;
  AccountBalanceSnapshot({
    required this.coin,
    required this.id,
    required this.balance,
  });

  bool sameAccount(AccountBalanceSnapshot other) =>
      coin == other.coin && id == other.id;

  @override
  String toString() => '($coin, $id, $balance)';
}

@freezed
class ProgressMessage with _$ProgressMessage {
  const factory ProgressMessage({
    required double progress,
    required String message,
  }) = _ProgressMessage;
}

@freezed
class SeedInfo with _$SeedInfo {
  const factory SeedInfo({
    required String seed,
    required int index,
    required bool scanTransparent,
  }) = _SeedInfo;
}

@freezed
class TxMemo with _$TxMemo {
  const factory TxMemo({
    required String address,
    required String memo,
  }) = _TxMemo;
}

@freezed
class SwapAmount with _$SwapAmount {
  const factory SwapAmount({
    required String amount,
    required String currency,
  }) = _SwapAmount;
}

@freezed
class SwapQuote with _$SwapQuote {
  const factory SwapQuote({
    required String estimated_amount,
    required String rate_id,
    required String valid_until,
  }) = _SwapQuote;

  factory SwapQuote.fromJson(Map<String, dynamic> json) =>
      _$SwapQuoteFromJson(json);
}

@freezed
class SwapRequest with _$SwapRequest {
  const factory SwapRequest({
    required bool fixed,
    required String rate_id,
    required String currency_from,
    required String currency_to,
    required double amount_from,
    required String address_to,
  }) = _SwapRequest;

  factory SwapRequest.fromJson(Map<String, dynamic> json) =>
      _$SwapRequestFromJson(json);
}

@freezed
class SwapLeg with _$SwapLeg {
  const factory SwapLeg({
    required String symbol,
    required String name,
    required String image,
    required String validation_address,
    required String address_explorer,
    required String tx_explorer,
  }) = _SwapLeg;

  factory SwapLeg.fromJson(Map<String, dynamic> json) =>
      _$SwapLegFromJson(json);
}

@freezed
class SwapResponse with _$SwapResponse {
  const factory SwapResponse({
    required String id,
    required String timestamp,
    required String currency_from,
    required String currency_to,
    required String amount_from,
    required String amount_to,
    required String address_from,
    required String address_to,
  }) = _SwapResponse;

  factory SwapResponse.fromJson(Map<String, dynamic> json) =>
      _$SwapResponseFromJson(json);
}

@freezed
class Election with _$Election {
  const factory Election({
    required String name,
    required int start_height,
    required int end_height,
    required int close_height,
    required String submit_url,
    required List<String> candidates,
    required String status,
  }) = _Election;

  factory Election.fromJson(Map<String, dynamic> json) =>
      _$ElectionFromJson(json);
}

@freezed
class Vote with _$Vote {
  const factory Vote({
    required Election election,
    required List<int> ids,
    int? candidate,
  }) = _Vote;
}

@freezed
class Servers with _$Servers {
  const factory Servers({
    required int coin,
    required List<Server> available,
    required List<String> selected,
  }) = _Servers;
}
