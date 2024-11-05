import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:binary/binary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';
import 'package:mobx/mobx.dart';

import '../../accounts.dart';
import '../../generated/intl/messages.dart';
import '../../store.dart';
import '../utils.dart';

class TransparentAddressesPage extends StatefulWidget {
  late final List<TransparentAddressT> addresses;

  TransparentAddressesPage() {
    addresses = warp.listTransparentAddresses(aa.coin, aa.id);
  }

  @override
  State<StatefulWidget> createState() => TransparentAddressesState();
}

class TransparentAddressesState extends State<TransparentAddressesPage> {
  late final S s = S.of(context);
  late List<TransparentAddressT> addresses = widget.addresses;
  bool external = true;

  @override
  Widget build(BuildContext context) {
    final addrs = addresses.where((a) => a.$external == (external ? 0 : 1)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.addresses), actions: [
        Switch(value: external, onChanged: (v) => setState(() => external = v)),
        IconButton(onPressed: add, icon: Icon(Icons.add)),
        IconButton(onPressed: scan, icon: Icon(Icons.radar)),
      ]),
      body: ListView.separated(
        itemBuilder: (context, i) {
          final a = addrs[i];
          return ListTile(
            onTap: external ? () => onPress(a) : null,
            leading: Text(a.addrIndex.toString()),
            trailing: Text(amountToString(a.amount)),
            title: Text(a.address!),
          );
        },
        separatorBuilder: (context, i) => Divider(),
        itemCount: addrs.length,
      ),
    );
  }

  onPress(TransparentAddressT a) async {
    final confirmed = await showConfirmDialog(context, s.updateTransparent, s.updateTransparentQuestion);
    if (confirmed) {
      tryWarpFn(context, () => warp.changeAccountAddrIndex(aa.coin, aa.id, a.addrIndex));
      aa.initialize();
      aaSequence.onAccountChanged();
    }
  }

  add() async {
    final confirm =
        await showConfirmDialog(context, s.add, s.addAddressConfirm);
    if (!confirm) return;
    try {
      warp.newTransparentAddress(aa.coin, aa.id, 0);
      setState(() {
        addresses = warp.listTransparentAddresses(aa.coin, aa.id);
        aaSequence.onAccountChanged();
      });
    } on String catch (msg) {
      await showMessageBox(context, s.error, msg, type: DialogType.error);
    }
  }

  scan() async {
    await GoRouter.of(context).push('/more/transparent/addresses/scan');
    setState(() {
      addresses = warp.listTransparentAddresses(aa.coin, aa.id);
    });
  }
}

class ListUTXOPage extends StatefulWidget {
  late final List<InputTransparentT> utxos;

  ListUTXOPage() {
    utxos = warp.listUtxos(aa.coin, aa.id, Int32.maxInt);
  }

  @override
  State<StatefulWidget> createState() => ListUTXOState();
}

class ListUTXOState extends State<ListUTXOPage> {
  late final S s = S.of(context);
  late List<InputTransparentT> utxos = widget.utxos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s.utxo), actions: []),
      body: ListView.separated(
        itemBuilder: (context, i) {
          final utxo = utxos[i];
          return ListTile(
            title: Text(utxo.address!),
            trailing: Text(amountToString(utxo.value)),
          );
        },
        separatorBuilder: (context, i) => Divider(),
        itemCount: utxos.length,
      ),
    );
  }
}

class ScanTransparentAddressesPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ScanTransparentAddressesState();
}

class ScanTransparentAddressesState extends State<ScanTransparentAddressesPage>
    with WithLoadingAnimation {
  late final S s = S.of(context);
  final formKey = GlobalKey<FormBuilderState>();
  final gapLimitController = TextEditingController(text: '40');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(s.scanTransparentAddresses),
          actions: [IconButton(onPressed: scan, icon: Icon(Icons.check))]),
      body: wrapWithLoading(
        Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: FormBuilder(
            key: formKey,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: 'gap',
                  controller: gapLimitController,
                  decoration: InputDecoration(label: Text(s.gapLimit)),
                  keyboardType: TextInputType.numberWithOptions(),
                  validator: FormBuilderValidators.integer(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  scan() async {
    final form = formKey.currentState!;
    if (!form.saveAndValidate()) return;
    final gapLimit = int.parse(gapLimitController.text);
    load(() async {
      await warp.scanTransparentAddresses(aa.coin, aa.id, 0, gapLimit);
      await warp.scanTransparentAddresses(aa.coin, aa.id, 1, gapLimit);
      await warp.transparentSync(aa.coin, aa.id, syncStatus.syncedHeight);
      aa.initialize();
      aaSequence.onAccountChanged();
      GoRouter.of(context).pop();
    });
  }
}
