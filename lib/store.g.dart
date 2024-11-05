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

  @override
  String toString() {
    return '''
price: ${price}
    ''';
  }
}
