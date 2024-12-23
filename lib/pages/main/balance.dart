import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:warp/data_fb_generated.dart';

import '../../appsettings.dart';
import '../../store.dart';
import '../../accounts.dart';
import '../../coin/coins.dart';
import '../utils.dart';

class BalanceWidget extends StatefulWidget {
  final BalanceT balance;
  final int mode;
  final void Function()? onMode;
  BalanceWidget(this.balance, this.mode, {this.onMode, super.key});
  @override
  State<StatefulWidget> createState() => BalanceState();
}

class BalanceState extends State<BalanceWidget> {
  late final accountBalance = widget.balance;

  String _formatFiat(double x) =>
      decimalFormat(x, 2, symbol: appSettings.currency);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final mode = widget.mode;

    final color = mode == 0
        ? t.colorScheme.secondary
        : mode == 1
            ? t.colorScheme.primaryContainer
            : t.colorScheme.primary;

    return Observer(builder: (context) {
      aaSequence.balanceSeqno;
      appStore.flat;
      marketPrice.price;

      final hideBalance = isHidden(appStore.flat);
      if (hideBalance) return SizedBox();

      final c = coins[aa.coin];
      final balHi = decimalFormat((balance ~/ 100000) / 1000.0, 3);
      final balLo = (balance % 100000).toString().padLeft(5, '0');
      final fiat = marketPrice.price;
      final balFiat = fiat?.let((fx) => balance * fx / ZECUNIT);
      final txtFiat = fiat?.let(_formatFiat);
      final txtBalFiat = balFiat?.let(_formatFiat);

      final balanceWidget = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(c.symbol, style: t.textTheme.bodyLarge),
          Text(balHi, style: t.textTheme.displayMedium?.apply(color: color)),
          Text(balLo, style: t.textTheme.bodyMedium)
        ],
      );
      final ob = otherBalance;

      return GestureDetector(
        onTap: widget.onMode,
        child: Column(
          children: [
            ob > 0
                ? InputDecorator(
                    decoration: InputDecoration(
                        label: Text('+ ${amountToString(ob)}'),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: t.primaryColor),
                            borderRadius: BorderRadius.circular(8))),
                    child: balanceWidget)
                : balanceWidget,
            Padding(padding: EdgeInsets.all(4)),
            if (txtBalFiat != null)
              Text(txtBalFiat, style: t.textTheme.titleLarge),
            if (txtFiat != null) Text('1 ${c.ticker} = $txtFiat'),
          ],
        ),
      );
    });
  }

  int get balance => accountBalance.masked(widget.mode);
  int get totalBalance => accountBalance.total;
  int get otherBalance => totalBalance - balance;
}

class UnconfirmedBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      aaSequence.balanceSeqno;
      appStore.flat;

      final amount = aa.unconfirmedBalance;
      final hideBalance = isHidden(appStore.flat);
      if (amount == 0 || hideBalance) return SizedBox.shrink();

      final t = Theme.of(context);
      final color =
          amount > 0 ? t.colorScheme.primary : t.colorScheme.secondary;
      final sign = amount > 0 ? '+' : '-';
      final amplitude = amount.abs();
      final hi = decimalFormat((amplitude ~/ 100000) / 1000.0, 3);
      final lo = (amplitude % 100000).toString().padLeft(5, '0');
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(sign, style: t.textTheme.titleLarge!.copyWith(color: color)),
          Text(hi, style: t.textTheme.titleLarge!.copyWith(color: color)),
          Text(lo, style: t.textTheme.labelMedium!.copyWith(color: color)),
        ],
      );
    });
  }
}

bool isHidden(bool flat) {
  switch (appSettings.autoHide) {
    case 0:
      return true;
    case 1:
      return flat;
    default:
      return false;
  }
}
