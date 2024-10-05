// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapQuoteImpl _$$SwapQuoteImplFromJson(Map<String, dynamic> json) =>
    _$SwapQuoteImpl(
      estimated_amount: json['estimated_amount'] as String,
      rate_id: json['rate_id'] as String,
      valid_until: json['valid_until'] as String,
    );

Map<String, dynamic> _$$SwapQuoteImplToJson(_$SwapQuoteImpl instance) =>
    <String, dynamic>{
      'estimated_amount': instance.estimated_amount,
      'rate_id': instance.rate_id,
      'valid_until': instance.valid_until,
    };

_$SwapRequestImpl _$$SwapRequestImplFromJson(Map<String, dynamic> json) =>
    _$SwapRequestImpl(
      fixed: json['fixed'] as bool,
      rate_id: json['rate_id'] as String,
      currency_from: json['currency_from'] as String,
      currency_to: json['currency_to'] as String,
      amount_from: (json['amount_from'] as num).toDouble(),
      address_to: json['address_to'] as String,
    );

Map<String, dynamic> _$$SwapRequestImplToJson(_$SwapRequestImpl instance) =>
    <String, dynamic>{
      'fixed': instance.fixed,
      'rate_id': instance.rate_id,
      'currency_from': instance.currency_from,
      'currency_to': instance.currency_to,
      'amount_from': instance.amount_from,
      'address_to': instance.address_to,
    };

_$SwapLegImpl _$$SwapLegImplFromJson(Map<String, dynamic> json) =>
    _$SwapLegImpl(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      validation_address: json['validation_address'] as String,
      address_explorer: json['address_explorer'] as String,
      tx_explorer: json['tx_explorer'] as String,
    );

Map<String, dynamic> _$$SwapLegImplToJson(_$SwapLegImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'image': instance.image,
      'validation_address': instance.validation_address,
      'address_explorer': instance.address_explorer,
      'tx_explorer': instance.tx_explorer,
    };

_$SwapResponseImpl _$$SwapResponseImplFromJson(Map<String, dynamic> json) =>
    _$SwapResponseImpl(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      currency_from: json['currency_from'] as String,
      currency_to: json['currency_to'] as String,
      amount_from: json['amount_from'] as String,
      amount_to: json['amount_to'] as String,
      address_from: json['address_from'] as String,
      address_to: json['address_to'] as String,
    );

Map<String, dynamic> _$$SwapResponseImplToJson(_$SwapResponseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp,
      'currency_from': instance.currency_from,
      'currency_to': instance.currency_to,
      'amount_from': instance.amount_from,
      'amount_to': instance.amount_to,
      'address_from': instance.address_from,
      'address_to': instance.address_to,
    };

_$ElectionImpl _$$ElectionImplFromJson(Map<String, dynamic> json) =>
    _$ElectionImpl(
      name: json['name'] as String,
      start_height: (json['start_height'] as num).toInt(),
      end_height: (json['end_height'] as num).toInt(),
      close_height: (json['close_height'] as num).toInt(),
      submit_url: json['submit_url'] as String,
      candidates: (json['candidates'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$$ElectionImplToJson(_$ElectionImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'start_height': instance.start_height,
      'end_height': instance.end_height,
      'close_height': instance.close_height,
      'submit_url': instance.submit_url,
      'candidates': instance.candidates,
      'status': instance.status,
    };

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AppStore on _AppStore, Store {
  late final _$flatAtom = Atom(name: '_AppStore.flat', context: context);

  @override
  bool get flat {
    _$flatAtom.reportRead();
    return super.flat;
  }

  @override
  set flat(bool value) {
    _$flatAtom.reportWrite(value, super.flat, () {
      super.flat = value;
    });
  }

  @override
  String toString() {
    return '''
flat: ${flat}
    ''';
  }
}

mixin _$SyncStatus on _SyncStatus, Store {
  Computed<int>? _$changedComputed;

  @override
  int get changed => (_$changedComputed ??=
          Computed<int>(() => super.changed, name: '_SyncStatus.changed'))
      .value;
  Computed<int>? _$expirationHeightComputed;

  @override
  int get expirationHeight => (_$expirationHeightComputed ??= Computed<int>(
          () => super.expirationHeight,
          name: '_SyncStatus.expirationHeight'))
      .value;

  late final _$connectedAtom =
      Atom(name: '_SyncStatus.connected', context: context);

  @override
  bool get connected {
    _$connectedAtom.reportRead();
    return super.connected;
  }

  @override
  set connected(bool value) {
    _$connectedAtom.reportWrite(value, super.connected, () {
      super.connected = value;
    });
  }

  late final _$syncedHeightAtom =
      Atom(name: '_SyncStatus.syncedHeight', context: context);

  @override
  int get syncedHeight {
    _$syncedHeightAtom.reportRead();
    return super.syncedHeight;
  }

  @override
  set syncedHeight(int value) {
    _$syncedHeightAtom.reportWrite(value, super.syncedHeight, () {
      super.syncedHeight = value;
    });
  }

  late final _$latestHeightAtom =
      Atom(name: '_SyncStatus.latestHeight', context: context);

  @override
  int? get latestHeight {
    _$latestHeightAtom.reportRead();
    return super.latestHeight;
  }

  @override
  set latestHeight(int? value) {
    _$latestHeightAtom.reportWrite(value, super.latestHeight, () {
      super.latestHeight = value;
    });
  }

  late final _$timestampAtom =
      Atom(name: '_SyncStatus.timestamp', context: context);

  @override
  DateTime? get timestamp {
    _$timestampAtom.reportRead();
    return super.timestamp;
  }

  @override
  set timestamp(DateTime? value) {
    _$timestampAtom.reportWrite(value, super.timestamp, () {
      super.timestamp = value;
    });
  }

  late final _$syncingAtom =
      Atom(name: '_SyncStatus.syncing', context: context);

  @override
  bool get syncing {
    _$syncingAtom.reportRead();
    return super.syncing;
  }

  @override
  set syncing(bool value) {
    _$syncingAtom.reportWrite(value, super.syncing, () {
      super.syncing = value;
    });
  }

  late final _$pausedAtom = Atom(name: '_SyncStatus.paused', context: context);

  @override
  bool get paused {
    _$pausedAtom.reportRead();
    return super.paused;
  }

  @override
  set paused(bool value) {
    _$pausedAtom.reportWrite(value, super.paused, () {
      super.paused = value;
    });
  }

  late final _$reloadSeqnoAtom =
      Atom(name: '_SyncStatus.reloadSeqno', context: context);

  @override
  int get reloadSeqno {
    _$reloadSeqnoAtom.reportRead();
    return super.reloadSeqno;
  }

  @override
  set reloadSeqno(int value) {
    _$reloadSeqnoAtom.reportWrite(value, super.reloadSeqno, () {
      super.reloadSeqno = value;
    });
  }

  late final _$downloadedSizeAtom =
      Atom(name: '_SyncStatus.downloadedSize', context: context);

  @override
  int get downloadedSize {
    _$downloadedSizeAtom.reportRead();
    return super.downloadedSize;
  }

  @override
  set downloadedSize(int value) {
    _$downloadedSizeAtom.reportWrite(value, super.downloadedSize, () {
      super.downloadedSize = value;
    });
  }

  late final _$trialDecryptionCountAtom =
      Atom(name: '_SyncStatus.trialDecryptionCount', context: context);

  @override
  int get trialDecryptionCount {
    _$trialDecryptionCountAtom.reportRead();
    return super.trialDecryptionCount;
  }

  @override
  set trialDecryptionCount(int value) {
    _$trialDecryptionCountAtom.reportWrite(value, super.trialDecryptionCount,
        () {
      super.trialDecryptionCount = value;
    });
  }

  late final _$updateBCHeightAsyncAction =
      AsyncAction('_SyncStatus.updateBCHeight', context: context);

  @override
  Future<void> updateBCHeight() {
    return _$updateBCHeightAsyncAction.run(() => super.updateBCHeight());
  }

  late final _$syncAsyncAction =
      AsyncAction('_SyncStatus.sync', context: context);

  @override
  Future<void> sync(bool rescan, {bool auto = false}) {
    return _$syncAsyncAction.run(() => super.sync(rescan, auto: auto));
  }

  late final _$rescanAsyncAction =
      AsyncAction('_SyncStatus.rescan', context: context);

  @override
  Future<void> rescan(int height) {
    return _$rescanAsyncAction.run(() => super.rescan(height));
  }

  late final _$_SyncStatusActionController =
      ActionController(name: '_SyncStatus', context: context);

  @override
  void reload() {
    final _$actionInfo =
        _$_SyncStatusActionController.startAction(name: '_SyncStatus.reload');
    try {
      return super.reload();
    } finally {
      _$_SyncStatusActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo =
        _$_SyncStatusActionController.startAction(name: '_SyncStatus.reset');
    try {
      return super.reset();
    } finally {
      _$_SyncStatusActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPause(bool v) {
    final _$actionInfo =
        _$_SyncStatusActionController.startAction(name: '_SyncStatus.setPause');
    try {
      return super.setPause(v);
    } finally {
      _$_SyncStatusActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setProgress(ProgressT progress) {
    final _$actionInfo = _$_SyncStatusActionController.startAction(
        name: '_SyncStatus.setProgress');
    try {
      return super.setProgress(progress);
    } finally {
      _$_SyncStatusActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
connected: ${connected},
syncedHeight: ${syncedHeight},
latestHeight: ${latestHeight},
timestamp: ${timestamp},
syncing: ${syncing},
paused: ${paused},
reloadSeqno: ${reloadSeqno},
downloadedSize: ${downloadedSize},
trialDecryptionCount: ${trialDecryptionCount},
changed: ${changed},
expirationHeight: ${expirationHeight}
    ''';
  }
}

mixin _$MarketPrice on _MarketPrice, Store {
  late final _$priceAtom = Atom(name: '_MarketPrice.price', context: context);

  @override
  double? get price {
    _$priceAtom.reportRead();
    return super.price;
  }

  @override
  set price(double? value) {
    _$priceAtom.reportWrite(value, super.price, () {
      super.price = value;
    });
  }

  late final _$updateAsyncAction =
      AsyncAction('_MarketPrice.update', context: context);

  @override
  Future<void> update() {
    return _$updateAsyncAction.run(() => super.update());
  }

  @override
  String toString() {
    return '''
price: ${price}
    ''';
  }
}

mixin _$ContactStore on _ContactStore, Store {
  late final _$contactsAtom =
      Atom(name: '_ContactStore.contacts', context: context);

  @override
  List<ContactCardT> get contacts {
    _$contactsAtom.reportRead();
    return super.contacts;
  }

  @override
  set contacts(List<ContactCardT> value) {
    _$contactsAtom.reportWrite(value, super.contacts, () {
      super.contacts = value;
    });
  }

  late final _$_ContactStoreActionController =
      ActionController(name: '_ContactStore', context: context);

  @override
  void remove(ContactCardT c) {
    final _$actionInfo = _$_ContactStoreActionController.startAction(
        name: '_ContactStore.remove');
    try {
      return super.remove(c);
    } finally {
      _$_ContactStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
contacts: ${contacts}
    ''';
  }
}
