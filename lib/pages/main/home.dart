import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:warp/warp.dart';

import '../../generated/intl/messages.dart';
import '../../appsettings.dart';
import '../../store.dart';
import '../../accounts.dart';
import '../utils.dart';
import 'balance.dart';
import 'sync_status.dart';
import 'qr_address.dart';

class HomePage extends StatelessWidget {
  final int? coin;
  HomePage({super.key, this.coin});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final key = ValueKey(aaSequence.seqno);
      return HomePageInner(key: key, coin: coin);
    });
  }
}

class HomePageInner extends StatefulWidget {
  final int? coin;
  HomePageInner({super.key, this.coin});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomePageInner> {
  int mask = 0;
  final formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    syncStatus.updateBCHeight();
  }

  @override
  void didUpdateWidget(covariant HomePageInner oldWidget) {
    // Switch the account if the current coin does not match
    super.didUpdateWidget(oldWidget);
    final c = widget.coin;
    if (c != null && c != aa.coin) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final account = warp.listAccounts(c).firstOrNull;
        if (account != null) {
          await setActiveAccount(account.coin, account.id);
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      floatingActionButton: GestureDetector(
          onLongPress: () => _send(true),
          child: FloatingActionButton(
            onPressed: () => _send(false),
            child: Icon(Icons.send),
          )),
      body: SingleChildScrollView(
        child: Center(
          child: Observer(
            builder: (context) {
              syncStatus.changed;
              aaSequence.seqno;
              final balance = warp.getBalance(aa.coin, aa.id, MAXHEIGHT);

              return Column(
                children: [
                  SyncStatusWidget(),
                  Gap(8),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        AddressCarousel(
                          onAddressModeChanged: (_, m) =>
                              setState(() => mask = m),
                          onQRPressed: () {
                            GoRouter.of(context).push('/account/payment_uri');
                          },
                        ),
                        Gap(8),
                        BalanceWidget(
                          key: ValueKey(balance),
                          balance,
                          mask & 7,
                        ),
                        Gap(8),
                        UnconfirmedBalance(),
                        Gap(16),
                        if (!aa.saved)
                          OutlinedButton(
                              onPressed: _backup, child: Text(s.backupMissing))
                      ])),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  _send(bool custom) async {
    final protectSend = appSettings.protectSend;
    if (protectSend) {
      final authed = await authBarrier(context, dismissable: true);
      if (!authed) return;
    }
    final c = custom ? 1 : 0;
    GoRouter.of(context).push('/account/send?custom=$c');
  }

  _backup() {
    GoRouter.of(context).push('/more/backup');
  }
}
