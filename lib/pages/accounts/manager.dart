import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';

import '../../appsettings.dart';
import '../../store.dart';
import '../../accounts.dart';
import '../../coin/coins.dart';
import '../../generated/intl/messages.dart';
import '../input_widgets.dart';
import '../utils.dart';
import '../widgets.dart';

class AccountManagerPage extends StatelessWidget {
  final bool main;
  AccountManagerPage({required this.main});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      aaSequence.accountListSeqno;

      final accounts = getAllAccounts();
      if (accounts.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).go('/welcome');
        });
        return SizedBox.shrink();
      }

      return AccountManager(
          key: ValueKey(aaSequence.accountListSeqno), accounts, main: main);
    });
  }
}

class AccountManager extends StatefulWidget {
  final bool main;
  final List<AccountNameT> accounts;

  AccountManager(this.accounts, {super.key, required this.main});
  @override
  State<StatefulWidget> createState() => _AccountManagerState();
}

class _AccountManagerState extends State<AccountManager> {
  late final s = S.of(context);
  int? selected;
  bool showAll = false;
  late var accounts = getAccounts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(s.accountManager), actions: [
          IconButton(
              onPressed: showHidden,
              icon: Icon(showAll ? Icons.visibility : Icons.visibility_off)),
          if (selected != null)
            IconButton(
                onPressed: () => edit(accounts[selected!]),
                icon: Icon(Icons.edit)),
          if (selected != null)
            IconButton(
                onPressed: () => delete(accounts[selected!]),
                icon: Icon(Icons.delete)),
          if (selected != null)
            IconButton(
                onPressed: () => cold(accounts[selected!]),
                icon: Icon(MdiIcons.snowflake)),
          if (selected == null)
            IconButton(onPressed: add, icon: Icon(Icons.add)),
        ]),
        body: AccountList(
          accounts,
          key: ValueKey(accounts),
          selected: selected,
          onSelect: (v) => select(accounts[v!]),
          onLongSelect: (v) => setState(() => selected = v),
          onReorder: onReorder,
        ));
  }

  showHidden() async {
    final confirmed = await authenticate(context, s.showAccounts);
    if (confirmed)
      setState(() {
        showAll = !showAll;
        accounts = getAccounts();
      });
  }

  List<AccountNameT> getAccounts() {
    final hideEmptyAccounts = appSettings.hideEmptyAccounts;
    return widget.accounts.where((a) =>
      (a.balance > 0 || !hideEmptyAccounts) &&
      (showAll || !a.hidden)).toList();
  }

  add() async {
    await GoRouter.of(context).push('/more/account_manager/new');
    _refresh();
  }

  select(AccountNameT a) {
    if (widget.main) {
      Future(() async {
        await setActiveAccount(a.coin, a.id);
        await aa.save();
        aa.initialize();
        aaSequence.onAccountChanged();
      });
    }
    GoRouter.of(context).pop<AccountNameT>(a);
  }

  delete(AccountNameT a) async {
    final confirmed = await showConfirmDialog(
        context, s.deleteAccount(a.name!), s.confirmDeleteAccount);
    if (confirmed) {
      if (a.coin == aa.coin && a.id == aa.id) {
        final other = widget.accounts.firstWhere(
            (a) => (a.coin != aa.coin || a.id != aa.id) && !a.hidden,
            orElse: () => AccountNameT());
        setActiveAccount(other.coin, other.id);
      }

      warp.deleteAccount(a.coin, a.id);
      _refresh();
    }
  }

  edit(AccountNameT a) async {
    await GoRouter.of(context).push('/account/edit', extra: a);
    aaSequence.onAccountChanged();
    aa.initialize();
    _refresh();
  }

  onReorder(int from, int to) {
    if (from < to) to -= 1;
    final a = accounts.removeAt(from);
    accounts.insert(to, a);
    warp.reorderAccount(a.coin, a.id, to);
    // do not refresh yet
  }

  cold(AccountNameT a) async {
    await GoRouter.of(context).push('/account/downgrade', extra: a);
    _refresh();
  }

  _refresh() {
    aaSequence.onAccountListChanged();
  }
}

class AccountList extends StatelessWidget {
  final List<AccountNameT> accounts;
  final int? selected;
  final void Function(int?)? onSelect;
  final void Function(int?)? onLongSelect;
  final void Function(int, int) onReorder;

  AccountList(
    this.accounts, {
    super.key,
    this.selected,
    this.onSelect,
    this.onLongSelect,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
        buildDefaultDragHandles: true,
        itemBuilder: (context, index) {
          final a = accounts[index];
          return AccountTile(
            a,
            key: ValueKey(a.id),
            selected: index == selected,
            onPress: () => onSelect?.call(index),
            onLongPress: () {
              final v = selected != index ? index : null;
              onLongSelect?.call(v);
            },
          );
        },
        onReorder: onReorder,
        itemCount: accounts.length);
  }
}

class AccountTile extends StatelessWidget {
  final AccountNameT a;
  final void Function()? onPress;
  final void Function()? onLongPress;
  final bool selected;
  late final nameController = TextEditingController(text: a.name);
  AccountTile(
    this.a, {
    super.key,
    this.onPress,
    this.onLongPress,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = coins[a.coin];

    return ListTile(
      contentPadding: EdgeInsets.only(left: 16, right: 48),
      selected: selected,
      leading: CircleAvatar(backgroundImage: c.image),
      title: Text(a.name!, style: t.textTheme.headlineSmall),
      trailing: Text(amountToString(a.balance)),
      onTap: onPress,
      onLongPress: onLongPress,
      selectedTileColor: t.colorScheme.inversePrimary,
    );
  }
}

class EditAccountPage extends StatefulWidget {
  final AccountNameT account;
  EditAccountPage(this.account, {super.key});
  @override
  State<StatefulWidget> createState() => EditAccountState();
}

class EditAccountState extends State<EditAccountPage> {
  late final S s = S.of(context);
  final formKey = GlobalKey<FormBuilderState>();
  late final nameController = TextEditingController(text: widget.account.name);
  late int birth = widget.account.birth;
  late bool hidden = widget.account.hidden;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(s.editAccount),
          actions: [IconButton(onPressed: ok, icon: Icon(Icons.check))]),
      body: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: FormBuilder(
          key: formKey,
          child: Column(children: [
            FormBuilderTextField(
                name: 'name',
                decoration: InputDecoration(label: Text(s.name)),
                controller: nameController),
            HeightPicker(
              birth,
                name: 'birth_height',
              label: Text(s.birthHeight),
              onChanged: (v) => setState(() => birth = v!),
            ),
            FormBuilderSwitch(
              name: 'hidden',
              title: Text(s.hidden),
              initialValue: hidden,
              onChanged: (v) => setState(() => hidden = v!),
            ),
          ]),
        ),
      ),
    );
  }

  ok() async {
    warp.editAccountName(
        widget.account.coin, widget.account.id, nameController.text);
    warp.editAccountBirthHeight(widget.account.coin, widget.account.id, birth);
    warp.editAccountHidden(widget.account.coin, widget.account.id, hidden);
    if (hidden &&
        widget.account.coin == aa.coin &&
        widget.account.id == aa.id) {
      // current account got hidden
      final a = warp
          .listAccounts(aa.coin)
          .firstWhere((a) => !a.hidden, orElse: () => AccountNameT());
      await setActiveAccount(a.coin, a.id);
    }
    GoRouter.of(context).pop();
  }
}

class DowngradeAccountPage extends StatefulWidget {
  final AccountNameT account;
  DowngradeAccountPage(this.account, {super.key});
  @override
  State<StatefulWidget> createState() => DowngradeAccountState();
}

class DowngradeAccountState extends State<DowngradeAccountPage> {
  late final S s = S.of(context);
  late final AccountSigningCapabilitiesT accountCaps =
      warp.getAccountCapabilities(widget.account.coin, widget.account.id);
  final formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    print(accountCaps);
    final labels = [
      Text(s.noKey),
      Text(s.viewingKey),
      Text(s.secretKey),
    ];

    return Scaffold(
      appBar: AppBar(
          title: Text(s.downgradeAccount),
          actions: [IconButton(onPressed: downgrade, icon: Icon(Icons.check))]),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: FormBuilder(
            key: formKey,
            child: Column(children: [
              FormBuilderCheckbox(
                  name: 'seed',
                  title: Text(s.seed),
                  enabled: accountCaps.transparent == 7 &&
                      accountCaps.sapling == 7 &&
                      accountCaps.orchard == 7,
                  initialValue: accountCaps.seed,
                  onChanged: (v) {
                    setState(() => accountCaps.seed = v!);
                  }),
              Gap(16),
              InputDecorator(
                  decoration: InputDecoration(label: Text(s.transparent)),
                  child: SegmentedPicker(
                    _initialValue(accountCaps.transparent),
                    name: 'transparent',
                    available: _available(accountCaps.transparent),
                    labels: labels,
                    multiSelectionEnabled: false,
                    onChanged: (v) {
                      uncheckSeed();
                      accountCaps.transparent = _selected(v!);
                    },
                  )),
              Gap(16),
              InputDecorator(
                  decoration: InputDecoration(label: Text(s.sapling)),
                  child: SegmentedPicker(
                    _initialValue(accountCaps.sapling),
                    name: 'sapling',
                    available: _available(accountCaps.sapling),
                    labels: labels,
                    multiSelectionEnabled: false,
                    onChanged: (v) {
                      uncheckSeed();
                      accountCaps.sapling = _selected(v!);
                    },
                  )),
              Gap(16),
              InputDecorator(
                  decoration: InputDecoration(label: Text(s.orchard)),
                  child: SegmentedPicker(
                    _initialValue(accountCaps.orchard),
                    name: 'orchard',
                    available: _available(accountCaps.orchard),
                    labels: labels,
                    multiSelectionEnabled: false,
                    onChanged: (v) {
                      uncheckSeed();
                      accountCaps.orchard = _selected(v!);
                    },
                  )),
            ]),
          ),
        ),
      ),
    );
  }

  uncheckSeed() {
    formKey.currentState!.fields['seed']!.setValue(false);
    accountCaps.seed = false;
  }

  downgrade() async {
    final confirmed =
        await showConfirmDialog(context, s.coldStorage, s.confirmWatchOnly);
    if (confirmed) {
      try {
        await warp.downgradeAccount(
            widget.account.coin, widget.account.id, accountCaps);
        aa.initialize();
        aaSequence.onAccountChanged();
        GoRouter.of(context).pop();
      } on String catch (e) {
        await showMessageBox(context, s.error, e);
      }
    }
  }

  int _initialValue(int caps) {
    // from capabilities to highest bit mask
    switch (caps & 3) {
      case 3:
        return 4;
      case 1:
        return 2;
      case 0:
      default:
        return 1;
    }
  }

  int _available(int caps) {
    // from capabilities to bit mask available
    switch (caps & 3) {
      case 3:
        return 7; // secret key -> no key + view + sk
      case 1:
        return 3;
      default:
        return 1;
    }
  }

  int _selected(int mask) {
    // from bit mask to key capabilities
    // inverse of _initialValue
    switch (mask) {
      case 4:
        return 3;
      case 2:
        return 1;
      case 1:
      default:
        return 0;
    }
  }
}
