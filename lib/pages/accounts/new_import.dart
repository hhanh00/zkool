import 'package:ZKool/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:warp/warp.dart';

import '../../store.dart';
import '../input_widgets.dart';
import '../utils.dart';
import '../../accounts.dart';
import '../../coin/coins.dart';
import '../../generated/intl/messages.dart';
import '../../pages/widgets.dart';

const defaultGapLimit = 2;

class NewImportAccountPage extends StatefulWidget {
  final bool first;
  final SeedInfo? seedInfo;
  NewImportAccountPage({required this.first, this.seedInfo});

  @override
  State<StatefulWidget> createState() => _NewImportAccountState();
}

class _NewImportAccountState extends State<NewImportAccountPage>
    with WithLoadingAnimation {
  late final s = S.of(context);
  int coin = 0;
  final formKey = GlobalKey<FormBuilderState>();
  final nameController = TextEditingController();
  String _key = '';
  final accountIndexController = TextEditingController(text: '0');
  int? _birthHeight;
  late List<FormBuilderFieldOption<int>> options;
  bool _restore = false;
  bool _transparentOnly = false;
  bool _scanTransparent = true;

  @override
  void initState() {
    super.initState();
    if (widget.first) nameController.text = 'Main';
    final si = widget.seedInfo;
    if (si != null) {
      _restore = true;
      _key = si.seed;
      _scanTransparent = si.scanTransparent;
      accountIndexController.text = si.index.toString();
    }
    options = coins.map((c) {
      return FormBuilderFieldOption(
          child: ListTile(
            title: Text(c.name),
            trailing: Image(image: c.image, height: 32),
          ),
          value: c.coin);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithLoading(Scaffold(
      appBar: AppBar(
        title: Text(s.newAccount),
        actions: [
          IconButton(onPressed: _onSettings, icon: Icon(Icons.settings)),
          IconButton(onPressed: _onOK, icon: Icon(Icons.add)),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: formKey,
            child: Column(
              children: [
                Image.asset('assets/icon.png', height: 128),
                Gap(16),
                FormBuilderTextField(
                    name: 'name',
                    decoration: InputDecoration(labelText: s.accountName),
                    controller: nameController,
                    enableSuggestions: true,
                    validator: FormBuilderValidators.required()),
                FormBuilderRadioGroup<int>(
                  decoration: InputDecoration(labelText: s.crypto),
                  orientation: OptionsOrientation.vertical,
                  name: 'coin',
                  initialValue: coin,
                  onChanged: (int? v) {
                    setState(() {
                      coin = v!;
                    });
                  },
                  options: options,
                ),
                FormBuilderSwitch(
                  name: 'restore',
                  title: Text(s.restoreAnAccount),
                  onChanged: (v) {
                    setState(() {
                      _restore = v!;
                    });
                  },
                ),
                if (_restore)
                  Column(children: [
                    TextQRPicker(
                      _key,
                      name: 'key',
                      label: Text(s.key),
                      validator: (v) => _checkKey(coin, v),
                      onSaved: (v) => setState(() => _key = v!),
                    ),
                    Gap(8),
                    FormBuilderSwitch(
                      name: 'transparent_only',
                      title: Text(s.transparentOnly),
                      onChanged: (v) => setState(() => _transparentOnly = v!),
                    ),
                    Gap(8),
                    FormBuilderTextField(
                      name: 'account_index',
                      decoration: InputDecoration(label: Text(s.accountIndex)),
                      controller: accountIndexController,
                      keyboardType: TextInputType.number,
                    ),
                    Gap(8),
                    HeightPicker(
                      syncStatus.syncedHeight,
                      name: 'birth_height',
                      label: Text(s.birthHeight),
                      onChanged: (h) => _birthHeight = h,
                    )
                  ]),
                // TODO: Ledger
                // if (_restore && coins[coin].supportsLedger && !isMobile())
                //   Padding(
                //     padding: EdgeInsets.all(8),
                //     child: ElevatedButton(
                //       onPressed: _importLedger,
                //       child: Text('Import From Ledger'),
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  _onOK() async {
    final form = formKey.currentState!;
    if (form.saveAndValidate()) {
      await load(() async {
        final index = int.parse(accountIndexController.text);
        final bool isNew = _key.isEmpty;
        if (isNew) _key = await warp.generateSeed();
        final latestHeight = await warp.getBCHeightOrNull(coin);
        final birthHeight =
            _birthHeight ?? latestHeight ?? syncStatus.syncedHeight;
        logger.d('createAccount 1');

        final account = await createNewAccount(coin, nameController.text, _key,
        index, birthHeight, _transparentOnly, _scanTransparent,
        isNew, latestHeight);

        if (account == null)
          form.fields['name']!.invalidate(s.thisAccountAlreadyExists);
        else {
          logger.d('createAccount 8');
          await setActiveAccount(coin, account);
          logger.d('createAccount 9');
          await aa.save();
          logger.d('createAccount 10');
          final accounts = warp.listAccounts(coin);
          logger.d('createAccount 11');
          if (accounts.length == 1) {
            try {
              // First account of a coin is synced
              await warp.resetChain(coin, birthHeight);
            } on String catch (msg) {
              await showSnackBar(msg); // non fatal
            }
          }
          if (widget.first) {
            GoRouter.of(context).go('/account');
          } else
            GoRouter.of(context).pop();
        }
      });
    }
  }

  String? _checkKey(int coin, String? v) {
    if (v == null || v.isEmpty) return null;
    if (!warp.isValidKey(coin, v)) return s.invalidKey;
    return null;
  }

  _onSettings() {
    GoRouter.of(context).push('/settings');
  }

  // _importLedger() async {
  //   try {
  //     final account =
  //         await WarpApi.importFromLedger(aa.coin, nameController.text);
  //     setActiveAccount(coin, account);
  //   } on String catch (msg) {
  //     formKey.currentState!.fields['key']!.invalidate(msg);
  //   }
  // }
}

Future<int?> createNewAccount(int coin, String name, String key, int index,
    int birth, bool tOnly, bool tScan, bool isNew, int? bcHeight) async {
  final context = rootNavigatorKey.currentContext!;
  final account =
      await warp.createAccount(coin, name, key, index, birth, tOnly, isNew);
  logger.d('createAccount 2');
  if (account < 0)
    return null;
  else {
    if (!isNew) {
      try {
        logger.d('createAccount 3');
        final caps = warp.getAccountCapabilities(coin, account);
        logger.d('createAccount 4');
        if (bcHeight != null) {
          logger.d('createAccount 5');
          if (tScan && caps.transparent & 4 != 0) {
            // has ext transparent key
            await tryWarpFn(
                context,
                () => warp.scanTransparentAddresses(
                    coin, account, 0, defaultGapLimit));
            await tryWarpFn(
                context,
                () => warp.scanTransparentAddresses(
                    coin, account, 1, defaultGapLimit));
          }
          logger.d('createAccount 6');
          await tryWarpFn(
              context, () => warp.transparentSync(coin, account, bcHeight));
          logger.d('createAccount 7');
        }
      } on String catch (msg) {
        await showSnackBar(msg); // non fatal
        return null;
      }
    }
  }
  return account;
}
