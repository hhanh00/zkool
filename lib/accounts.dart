import 'dart:isolate';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'package:velocity_x/velocity_x.dart';
import 'appsettings.dart';
import 'coin/coins.dart';
import 'package:mobx/mobx.dart';
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';

import 'pages/utils.dart';
import 'store.dart';

part 'accounts.g.dart';

final ActiveAccount nullAccount = ActiveAccount(0, 0);

ActiveAccount aa = nullAccount;

AASequence aaSequence = AASequence();
class AASequence = _AASequence with _$AASequence;

abstract class _AASequence with Store {
  @observable
  int accountListSeqno = 0;

  @observable
  int accountSeqno = 0;

  @observable
  int settingsSeqno = 0;

  @observable
  int syncSeqno = 0;

  @observable
  int syncProgressSeqno = 0;

  @observable
  int balanceSeqno = 0;

  @observable
  int divAddressSeqno = 0;

  @observable
  int txsSeqno = 0;

  @observable
  int notesSeqno = 0;

  @observable
  int messagesSeqno = 0;

  @observable
  int contactsSeqno = 0;

  @action
  void onSettingsChanged() {
    settingsSeqno = DateTime.now().microsecondsSinceEpoch;
    onAccountChanged();
  }

  @action
  void onAccountListChanged() {
    logger.i('onAccountListChanged');
    accountListSeqno = DateTime.now().microsecondsSinceEpoch;
    onAccountDataChanged();
  }

  // current account changed
  @action
  void onAccountChanged() {
    accountSeqno = DateTime.now().microsecondsSinceEpoch;
    onAccountDataChanged();
  }

  @action
  void onSyncProgressChanged() {
    syncProgressSeqno = DateTime.now().microsecondsSinceEpoch;
  }

  // current account has new synchronization data
  @action
  void onAccountDataChanged() {
    syncSeqno = DateTime.now().microsecondsSinceEpoch;
    onBalanceChanged();
    onTxsChanged();
    onNotesChanged();
    onMessagesChanged();
    onContactsChanged();
  }

  @action
  void onTxsChanged() {
    txsSeqno = DateTime.now().microsecondsSinceEpoch;
  }

  @action
  void onNotesChanged() {
    notesSeqno = DateTime.now().microsecondsSinceEpoch;
  }

  @action
  void onMessagesChanged() {
    messagesSeqno = DateTime.now().microsecondsSinceEpoch;
  }
  @action

  void onContactsChanged() {
    contactsSeqno = DateTime.now().microsecondsSinceEpoch;
  }

  @action
  void onBalanceChanged() {
    balanceSeqno = DateTime.now().microsecondsSinceEpoch;
  }

  @action
  void onDivAddressChanged() {
    divAddressSeqno = DateTime.now().microsecondsSinceEpoch;
  }
}

Future<void> setActiveAccount(int coin, int id) async {
  final account = ActiveAccount.fromId(coin, id);
  account.initialize();
  aa = account;
  coinSettings = await CoinSettingsExtension.load(coin);
  coinSettings.account = id;
  coinSettings.save(coin);
  warp.mempoolSetAccount(coin, id);
  aaSequence.onAccountChanged();
}

class ActiveAccount {
  final int coin;
  final int id;

  String name = '';
  String? seed;
  bool saved = false;

  Notes notes;
  Txs txs;
  Messages messages;

  int unconfirmedBalance = 0;
  String diversifiedAddress = '';

  List<SpendingT> spendings = [];
  List<TimeSeriesPoint<double>> accountBalances = [];

  ActiveAccount(
      this.coin, this.id)
      : notes = Notes(coin, id),
        txs = Txs(coin, id),
        messages = Messages(coin, id) {
  }

  static Future<ActiveAccount?> fromPrefs(SharedPreferences prefs) async {
    final coin = prefs.getInt('coin') ?? 0;
    var id = prefs.getInt('account') ?? 0;
    final accounts = await warp.listAccounts(coin);
    final a =
        accounts.singleWhere((a) => a.id == id, orElse: () => AccountNameT());
    if (a.id != 0) return ActiveAccount.fromId(coin, id);
    for (var c in coins) {
      final accounts = await warp.listAccounts(coin);
      if (accounts.isNotEmpty)
        return ActiveAccount.fromId(c.coin, accounts[0].id);
    }
    return null;
  }

  factory ActiveAccount.fromId(int coin, int id) {
    if (id == 0) return nullAccount;
    return ActiveAccount(coin, id);
  }

  void initialize() {
    if (id == 0) return;
    final backup = warp.getBackup(coin, id);
    // TODO: Ledger -> c.supportsLedger && !isMobile() && WarpApi.ledgerHasAccount(coin, id);`
    name = backup.name!;
    seed = backup.seed;
    saved = backup.saved;

    updateDivisified();
    final h = syncStatus.latestHeight;
    notes.read(h);
    updateTxs(h);
    messages.read();
  }

  Future<void> save() async {
    final prefs = GetIt.I.get<SharedPreferences>();
    await prefs.setInt('coin', coin);
    await prefs.setInt('account', id);
  }

  void updateDivisified() {
    if (id == 0) return;
    final caps = warp.getAccountCapabilities(coin, id);
    if (caps.sapling == 0 && caps.orchard == 0) {
      diversifiedAddress = warp.getAccountAddress(
          coin, id, now(), (coinSettings.uaType & 6) | 8);
      aaSequence.onDivAddressChanged();
    }
  }

  void updateUnconfirmedBalance() {
    final b = warp.getUnconfirmedBalance(coin, id);
    if (b != unconfirmedBalance) {
      unconfirmedBalance = b;
      updateTxs(syncStatus.latestHeight);
      aaSequence.onBalanceChanged();
    }
  }

  // read confirmed & merge with unconfirmed txs
  void updateTxs(int bcHeight) {
    txs.read(bcHeight);
    final unconfirmedTx = warp.listUnconfirmedTxs(aa.coin, aa.id).map((tx) {
      final txid = Uint8List.fromList(tx.txid!);
      return Tx(0, 0, 0, DateTime.now(), centerTrim(reversedHex(txid)), txid,
          tx.value, null, null, "");
    }).toList();
    txs.items.insertAll(0, unconfirmedTx);
    aaSequence.onTxsChanged();
  }

  void update(int bcHeight) {
    if (id == 0) return;
    updateDivisified();

    notes.read(bcHeight);
    updateTxs(bcHeight);
    messages.read();

    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final start =
        today.add(Duration(days: -365)).millisecondsSinceEpoch ~/ 1000;
    final end = today.millisecondsSinceEpoch ~/ 1000;
    spendings = warp.getSpendings(coin, id, start);

    List<AccountBalance> abs = [];
    final balance = warp.getBalance(aa.coin, aa.id, syncStatus.confirmHeight);
    var b = balance.orchard + balance.sapling;
    abs.add(AccountBalance(DateTime.now(), b / ZECUNIT));
    for (var trade
        in txs.items.sortedBy((a, b) => b.height.compareTo(a.height))) {
      final timestamp = trade.timestamp;
      final value = trade.value;
      final ab = AccountBalance(timestamp, b / ZECUNIT);
      abs.add(ab);
      b -= value;
    }
    abs.add(AccountBalance(
        DateTime.fromMillisecondsSinceEpoch(start * 1000), b / ZECUNIT));
    accountBalances = sampleDaily<AccountBalance, double, double>(
        abs.reversed,
        start,
        end,
        (AccountBalance ab) => ab.time.millisecondsSinceEpoch ~/ DAY_MS,
        (AccountBalance ab) => ab.balance,
        (acc, v) => v,
        0.0);

    aaSequence.onAccountDataChanged();
  }
}

class Notes {
  final int coin;
  final int id;
  Notes(this.coin, this.id);

  List<Note> items = [];
  SortConfig2? order;

  Future<void> read(int height) async {
    final shieledNotes = await warp.listNotes(coin, id, MAXHEIGHT);
    items = shieledNotes.map((n) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(n.timestamp * 1000);
      return Note.from(height, n.idNote, n.height, timestamp, n.value / ZECUNIT,
          n.orchard, n.excluded, false);
    }).toList();
    _notifyChanged();
  }

  void clear() {
    items.clear();
    _notifyChanged();
  }

  void invert() async {
    await warp.reverseNoteExclusion(coin, id);
    items = items.map((n) => n.invertExcluded).toList();
    _notifyChanged();
  }

  void exclude(Note note) async {
    await warp.excludeNote(coin, note.id, note.excluded);
    items = List.of(items);
    _notifyChanged();
  }

  void setSortOrder(String field) {
    final r = _sort(field, order, items);
    order = r.item1;
    items = r.item2;
    _notifyChanged();
  }

  _notifyChanged() {
    aaSequence.onNotesChanged();
  }
}

class Txs {
  final int coin;
  final int id;
  Txs(this.coin, this.id);

  List<Tx> items = [];
  SortConfig2? order;

  void read(int? height) {
    final shieldedTxs = warp.listTransactions(coin, id, MAXHEIGHT);
    items = shieldedTxs.map((tx) {
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
      final fullTxId = Uint8List.fromList(tx.txid!);
      return Tx.from(
          height,
          tx.id,
          tx.height,
          timestamp,
          centerTrim(reversedHex(fullTxId)),
          fullTxId,
          tx.amount,
          tx.address,
          tx.contact,
          tx.memo ?? '');
    }).toList();
    items = items.sortedByNum((tx) => tx.height == 0 ? -MAXHEIGHT : -tx.height);
    _notifyChanged();
  }

  void clear() {
    items.clear();
    _notifyChanged();
  }

  void setSortOrder(String field) {
    final r = _sort(field, order, items);
    order = r.item1;
    items = r.item2;
    _notifyChanged();
  }

  void _notifyChanged() {
    aaSequence.onTxsChanged();
  }
}

class Messages {
  final int coin;
  final int id;
  Messages(this.coin, this.id);

  List<ZMessage> items = [];
  SortConfig2? order;

  Future<void> read() async {
    final ms = await warp.listMessages(coin, id);
    items = ms.map((m) {
      final memo = m.memo ??
          UserMemoT(
            sender: '',
            recipient: '',
            subject: '',
            body: '',
          );
      return ZMessage(
          m.idMsg,
          m.idTx,
          m.incoming,
          memo.sender,
          memo.sender,
          memo.recipient!,
          m.contact ?? '',
          memo.subject!,
          memo.body!,
          DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000),
          m.height,
          m.read);
    }).toList();
  }

  void clear() {
    items.clear();
  }

  void setSortOrder(String field) {
    final r = _sort(field, order, items);
    order = r.item1;
    items = r.item2;
    aaSequence.onMessagesChanged();
  }
}

Tuple2<SortConfig2?, List<T>> _sort<T extends HasHeight>(
    String field, SortConfig2? order, List<T> items) {
  if (order == null)
    order = SortConfig2(field, 1);
  else
    order = order.next(field);

  final o = order;
  if (o == null)
    items = items.sortedByNum((n) {
      final h = n.height == 0 ? MAXHEIGHT : n.height;
      return -h;
    });
  else {
    items = items.sortedBy((a, b) {
      final ra = reflector.reflect(a);
      final va = ra.invokeGetter(field)! as dynamic;
      final rb = reflector.reflect(b);
      final vb = rb.invokeGetter(field)! as dynamic;
      return va.compareTo(vb) * o.orderBy;
    });
  }
  return Tuple2(o, items);
}

class SortConfig2 {
  String field;
  int orderBy; // 1: asc, -1: desc
  SortConfig2(this.field, this.orderBy);

  SortConfig2? next(String newField) {
    if (newField == field) {
      if (orderBy > 0) return SortConfig2(field, -orderBy);
      return null;
    }
    return SortConfig2(newField, 1);
  }

  String indicator(String field) {
    if (this.field != field) return '';
    if (orderBy > 0) return ' \u2191';
    return ' \u2193';
  }
}
