import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';

import '../../appsettings.dart';
import '../../store.dart';
import '../utils.dart';
import '../../accounts.dart';
import '../../generated/intl/messages.dart';

class TxPlanPage extends StatefulWidget {
  final bool signOnly;
  final TransactionSummaryT plan;
  final String tab;
  TxPlanPage(this.plan, {required this.tab, this.signOnly = false});

  @override
  State<StatefulWidget> createState() => TxPlanState();
}

class TxPlanState extends State<TxPlanPage> with WithLoadingAnimation {
  late final s = S.of(context);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = Theme.of(context);
    final plan = widget.plan;
    final canSign = warp.canSign(aa.coin, aa.id, plan);

    final rows = plan.recipients!.where((e) => !e.change).map((e) {
      final receivers = warp.decodeAddress(aa.coin, e.address!);
      final style = styleOfAddress(receivers, t);
      final pool = poolOfAddress(receivers, s);
      return DataRow(cells: [
        DataCell(Text('${centerTrim(e.address!)}', style: style)),
        DataCell(Text('$pool', style: style)),
        DataCell(Text('${amountToString(e.amount, digits: MAX_PRECISION)}',
            style: style)),
      ]);
    }).toList();
    final feeStructure =
        """${plan.numInputs![0]}:${plan.numOutputs![0]} + ${plan.numInputs![1]}:${plan.numOutputs![1]} + ${plan.numInputs![2]}:${plan.numOutputs![2]}""";

    final invalidPrivacy = plan.privacyLevel < appSettings.minPrivacyLevel;
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green];
    final privacyColor = colors[plan.privacyLevel];
    final fColor =
        privacyColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final privacy = S
        .of(context)
        .privacy(getPrivacyLevel(context, plan.privacyLevel).toUpperCase());

    return Scaffold(
      appBar: AppBar(
        title: Text(s.txPlan),
        actions: [
          IconButton(
            onPressed: exportRaw,
            icon: Icon(MdiIcons.snowflake),
          ),
          if (canSign && !invalidPrivacy)
            IconButton(
              onPressed: sendOrSign,
              icon: widget.signOnly
                  ? FaIcon(FontAwesomeIcons.signature)
                  : Icon(Icons.send),
            )
        ],
      ),
      body: wrapWithLoading(
        SingleChildScrollView(
          child: Column(
            children: [
              Row(children: [
                Expanded(
                    child: DataTable(
                        headingRowHeight: 32,
                        columnSpacing: 32,
                        columns: [
                          DataColumn(label: Text(s.address)),
                          DataColumn(label: Text(s.pool)),
                          DataColumn(label: Expanded(child: Text(s.amount))),
                        ],
                        rows: rows))
              ]),
              Divider(
                height: 16,
                thickness: 2,
                color: t.primaryColor,
              ),
              ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(s.transparentInput),
                  trailing: Text(
                      amountToString(plan.transparentIns,
                          digits: MAX_PRECISION),
                      style: TextStyle(color: t.primaryColor))),
              ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(s.netSapling),
                  trailing: Text(
                      amountToString(plan.saplingNet, digits: MAX_PRECISION),
                      style: TextStyle(color: t.primaryColor))),
              ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(s.netOrchard),
                  trailing: Text(
                      amountToString(plan.orchardNet, digits: MAX_PRECISION),
                      style: TextStyle(color: t.primaryColor))),
              ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(s.fee),
                  subtitle: Text(feeStructure),
                  trailing: Text(
                      amountToString(plan.fee, digits: MAX_PRECISION),
                      style: TextStyle(color: t.primaryColor))),
              ElevatedButton.icon(
                  onPressed: invalidPrivacy ? null : sendOrSign,
                  label: Text(privacy),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: privacyColor, foregroundColor: fColor)),
              Gap(16),
              if (invalidPrivacy)
                Text(s.privacyLevelTooLow, style: t.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  send() async {
    await load(() async {
      final results = await tryWarpFn(context, () async {
        final txBytes =
            await warp.sign(aa.coin, widget.plan, syncStatus.expirationHeight);
        return await warp.broadcast(aa.coin, txBytes);
      });
      if (results != null) {
        final redirect = widget.plan.redirect;
        if (redirect != null)
          GoRouter.of(context).go(redirect);
        else
          GoRouter.of(context)
              .go('/${widget.tab}/broadcast_tx', extra: results);
      }
    });
  }

  exportRaw() {
    GoRouter.of(context).go('/account/export_raw_tx', extra: widget.plan);
  }

  Future<void> sendOrSign() async => widget.signOnly ? sign() : await send();

  sign() async {
    try {
      await load(() async {
        final txBytes =
            await warp.sign(aa.coin, widget.plan, syncStatus.expirationHeight);
        final builder = fb.Builder();
        final root = txBytes.pack(builder);
        builder.finish(root);
        GoRouter.of(context).go('/more/signed', extra: builder.buffer);
      });
    } on String catch (error) {
      await showMessageBox(context, s.error, error, type: DialogType.error);
    }
  }
}

TextStyle styleOfAddress(UareceiversT ua, ThemeData t) {
  if (ua.orchard != null) return TextStyle(color: t.primaryColor);
  if (ua.sapling != null) return TextStyle();
  if (ua.transparent != null) return TextStyle(color: t.colorScheme.error);
  return TextStyle();
}

String poolOfAddress(UareceiversT ua, S s) {
  if (ua.orchard != null) return s.orchard;
  if (ua.sapling != null) return s.sapling;
  if (ua.transparent != null) return s.transparent;
  return s.na;
}

String poolToString(S s, int pool) {
  switch (pool) {
    case 0:
      return s.transparent;
    case 1:
      return s.sapling;
  }
  return s.orchard;
}

Widget? privacyToString(BuildContext context, int privacyLevel,
    {required bool canSend,
    Future<void> Function(BuildContext context)? onSend}) {
  final m = S
      .of(context)
      .privacy(getPrivacyLevel(context, privacyLevel).toUpperCase());
  final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green];
  return getColoredButton(context, m, colors[privacyLevel],
      canSend: canSend, onSend: onSend);
}

ElevatedButton getColoredButton(BuildContext context, String text, Color color,
    {required bool canSend,
    Future<void> Function(BuildContext context)? onSend}) {
  var foregroundColor =
      color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  final doSend = () => onSend?.call(context);
  return ElevatedButton(
      onLongPress: doSend,
      onPressed: canSend ? doSend : null,
      child: Text(text),
      style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: foregroundColor));
}
