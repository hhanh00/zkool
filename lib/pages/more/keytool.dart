import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';

import '../../router.dart';
import '../../accounts.dart';
import '../../coin/coins.dart';
import '../../generated/intl/messages.dart';
import '../../store.dart';
import '../../tablelist.dart';
import '../../pages/utils.dart';
import '../accounts/new_import.dart';
import '../widgets.dart';

class KeyToolFormPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => KeyToolFormState();
}

class KeyToolFormState extends State<KeyToolFormPage>
    with WithLoadingAnimation {
  late final S s = S.of(context);
  final formKey = GlobalKey<FormBuilderState>();
  final accountController = TextEditingController(text: '0');
  bool incAccount = false;
  final addressController = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    return wrapWithLoading(Scaffold(
      appBar: AppBar(
        title: Text(s.keyTool),
        actions: [
          IconButton(onPressed: calculate, icon: Icon(Icons.calculate)),
        ],
      ),
      body: FormBuilder(
        key: formKey,
        child: Column(
          children: [
            FormBuilderTextField(
              name: 'account',
              decoration: InputDecoration(label: Text(s.accountIndex)),
              controller: accountController,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.integer(),
              ]),
            ),
            FormBuilderSwitch(
              name: 'incAccount',
              title: Text(s.incAccount),
              initialValue: incAccount,
              onChanged: (v) => setState(() => incAccount = v!),
            ),
            if (!incAccount)
              FormBuilderTextField(
                name: 'address',
                decoration: InputDecoration(label: Text(s.addressIndex)),
                controller: addressController,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.integer(),
                ]),
              ),
          ],
        ),
      ),
    ));
  }

  calculate() async {
    final form = formKey.currentState!;
    if (form.saveAndValidate()) {
      final account = int.parse(accountController.text);
      final addressIndex = int.parse(addressController.text);

      await load(() async {
        // calculate list of Zip32Keys
        List<Zip32KeysT> keys = [];
        for (var i = 0; i < 100; i++) {
          if (incAccount)
            keys.add(await warp.deriveZip32Keys(
                aa.coin, aa.id, account + i, 0, true));
          else
            keys.add(await warp.deriveZip32Keys(
                aa.coin, aa.id, account, addressIndex + i, false));
        }
        final incAccount2 = incAccount ? 1 : 0;
        GoRouter.of(context)
            .push('/more/keytool/results?account=$incAccount2', extra: keys);
      });
    }
  }
}

class KeyToolPage extends StatefulWidget {
  final List<Zip32KeysT> keys;
  final bool incAccount;

  KeyToolPage(this.keys, {super.key, required this.incAccount});

  @override
  State<StatefulWidget> createState() => _KeyToolState();
}

class _KeyToolState extends State<KeyToolPage> with WithLoadingAnimation {
  late final seed = aa.seed!;
  final formKey = GlobalKey<FormBuilderState>();
  bool shielded = false;
  int account = 0;
  int addrIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final keys = widget.keys;
    return Scaffold(
        appBar: AppBar(
          title: Text(s.keyTool),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AdvancedSwitch(
                activeChild: Text('S'),
                inactiveChild: Text('T'),
                initialValue: shielded,
                onChanged: (v) => setState(() => shielded = v),
              ),
            )
          ],
        ),
        body: wrapWithLoading(Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TableListPage(
              view: 2,
              items: keys,
              metadata: TableListKeyMetadata(
                  seed: seed,
                  incAccount: widget.incAccount,
                  shielded: shielded,
                  accountIndex: account,
                  addressIndex: addrIndex,
                  formKey: formKey),
            ))));
  }
}

class TableListKeyMetadata extends TableListItemMetadata<Zip32KeysT> {
  final s = S.of(rootNavigatorKey.currentContext!);
  final String seed;
  final bool incAccount;
  final coinIndex = coins[aa.coin].coinIndex;
  final int accountIndex;
  final int addressIndex;
  final bool shielded;
  int? selection;
  final GlobalKey<FormBuilderState> formKey;
  TableListKeyMetadata(
      {required this.seed,
      required this.incAccount,
      required this.shielded,
      required this.accountIndex,
      required this.addressIndex,
      required this.formKey});

  @override
  List<ColumnDefinition> columns(BuildContext context) {
    return [
      ColumnDefinition(label: s.index),
      ColumnDefinition(label: s.derpath),
      ColumnDefinition(label: s.address, field: 'address'),
      ColumnDefinition(label: s.secretKey, field: 'sk'),
    ];
  }

  @override
  Widget toListTile(BuildContext context, int index, Zip32KeysT item,
      {void Function(void Function())? setState}) {
    logger.d(item);
    final address = shielded ? item.zaddress : item.taddress!;
    final key = shielded ? item.zsk! : item.tsk!;
    final derPath = path(item);
    final selected = selection == index;
    final idx = shielded ? accountIndex + index : addressIndex + index;

    return GestureDetector(
      onTap: () => setState?.call(() => selection = !selected ? index : null),
      child: Card(
          margin: EdgeInsets.all(8),
          child: selected
              ? Column(
                  children: [
                    Panel(s.index, text: idx.toString()),
                    Gap(8),
                    Panel(s.derpath, text: derPath),
                    Gap(8),
                    Panel(s.address, text: address ?? s.na),
                    Gap(8),
                    Panel(s.secretKey, text: key),
                    Gap(8),
                    // Show the add account button if the account # are incremented
                    if (incAccount)
                      IconButton(
                        onPressed: () => addSubAccount(
                          context,
                          seed,
                          idx,
                        ),
                        icon: Icon(Icons.add),
                      ),
                  ],
                )
              : ListTile(
                  leading: Text(idx.toString()), title: Text(address ?? s.na))),
    );
  }

  @override
  DataRow toRow(BuildContext context, int index, Zip32KeysT item) {
    final idx = shielded ? accountIndex + index : addressIndex + index;
    final address = shielded ? item.zaddress : item.taddress;
    final key = shielded ? item.zsk! : item.tsk!;

    return DataRow.byIndex(index: index, cells: [
      DataCell(Text(idx.toString())),
      DataCell(Text(path(item))),
      DataCell(Text(address ?? s.na)),
      DataCell(Text(key)),
    ]);
  }

  String path(Zip32KeysT item) {
    return shielded
        ? "m/32'/$coinIndex'/${item.aindex}'/0/[${item.addrIndex}]"
        : "m/44'/$coinIndex'/${item.aindex}'/0/${item.addrIndex}";
  }

  @override
  List<Widget>? actions(BuildContext context) => null;

  @override
  Text? headerText(BuildContext context) => null;

  @override
  void inverseSelection() {}

  @override
  SortConfig2? sortBy(String field) => null;

  @override
  Widget? header(BuildContext context) => null;
}

void addSubAccount(BuildContext context, String seed, int index) {
  GoRouter.of(context).push('/more/account_manager/new',
      extra: SeedInfo(seed: seed, index: index, scanTransparent: false));
}

class BatchCreatePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => BatchCreateState();
}

class BatchCreateState extends State<BatchCreatePage> {
  late final S s = S.of(context);
  final formKey = GlobalKey<FormBuilderState>();
  final prefixController = TextEditingController();
  final startController = TextEditingController(text: '0');
  final countController = TextEditingController(text: '10');
  bool transparentOnly = false;
  int birthHeight = warp.getActivationHeight(aa.coin);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(s.batchCreate),
        actions: [IconButton(onPressed: onOk, icon: Icon(Icons.check))],
      ),
      body: FormBuilder(
        key: formKey,
        child: Column(
          children: [
            FormBuilderTextField(
              name: 'prefix',
              decoration: InputDecoration(label: Text(s.prefix)),
              controller: prefixController,
            ),
            Gap(8),
            FormBuilderTextField(
              name: 'start',
              decoration: InputDecoration(label: Text(s.start)),
              controller: startController,
              keyboardType: TextInputType.numberWithOptions(),
              validator: FormBuilderValidators.integer(),
            ),
            Gap(8),
            FormBuilderTextField(
              name: 'count',
              decoration: InputDecoration(label: Text(s.count)),
              controller: countController,
              keyboardType: TextInputType.numberWithOptions(),
              validator: FormBuilderValidators.integer(),
            ),
            Gap(8),
            HeightPicker(birthHeight,
                name: 'birth_height',
                label: Text(s.birthHeight),
                onChanged: (v) => birthHeight = v!),
            Gap(8),
            FormBuilderSwitch(
                name: 'transparent_only',
                title: Text(s.transparentOnly),
                onChanged: (v) => transparentOnly = v!)
          ],
        ),
      ),
    );
  }

  onOk() async {
    final form = formKey.currentState!;
    if (form.saveAndValidate()) {
      final confirmed =
          await showConfirmDialog(context, s.confirm, s.confirmBatchCreate);
      if (confirmed) {
        final prefix = prefixController.text;
        final start = int.parse(startController.text);
        final count = int.parse(countController.text);
        for (var i = 0; i < count; i++) {
          final accountIndex = start + i;
          final name = '$prefix$accountIndex';
          await tryWarpFn(
              context,
              () => createNewAccount(
                  aa.coin,
                  name,
                  aa.seed!,
                  accountIndex,
                  birthHeight,
                  transparentOnly,
                  true,
                  false,
                  syncStatus.latestHeight,
                  null));
        }
        aaSequence.onAccountListChanged();
        GoRouter.of(context).pop();
      }
    }
  }
}
