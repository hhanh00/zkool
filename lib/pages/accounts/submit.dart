import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:warp/data_fb_generated.dart';
import 'package:warp/warp.dart';

import '../../accounts.dart';
import '../../generated/intl/messages.dart';
import '../utils.dart';
import '../widgets.dart';

class SubmitTxPage extends StatelessWidget {
  final String data;
  final String? redirect;
  SubmitTxPage(this.data, {super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final txId = jsonDecode(data);

    return Scaffold(
      appBar: AppBar(title: Text(s.sent), actions: [
        IconButton(onPressed: () => ok(context), icon: Icon(Icons.check)),
      ]),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Jumbotron(txId, title: s.txID),
          Gap(16),
          OutlinedButton(
              onPressed: () => openTx(txId), child: Text(s.openInExplorer))
        ],
      ),
    );
  }

  openTx(String txId) {
    openTxInExplorer(txId);
  }

  ok(BuildContext context) {
    GoRouter.of(context).pop();
  }
}

class AnimatedQRExportPage extends StatefulWidget {
  final Uint8List data;
  final String title;
  final String filename;

  AnimatedQRExportPage(this.data,
      {super.key, required this.title, required this.filename});

  @override
  State<StatefulWidget> createState() => AnimatedQRExportState();
}

class AnimatedQRExportState extends State<AnimatedQRExportPage> {
  late final List<PacketT> packets;

  @override
  void initState() {
    super.initState();
    packets = warp.splitData(widget.data, 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          actions: [IconButton(onPressed: export, icon: Icon(Icons.save))]),
      body: packets.isNotEmpty
          ? AnimatedQR(widget.title, s.scanQrCode, packets, widget.data.length)
          : SizedBox.shrink(),
    );
  }

  export() async {
    await saveFileBinary(widget.data, widget.filename, widget.title);
  }
}
