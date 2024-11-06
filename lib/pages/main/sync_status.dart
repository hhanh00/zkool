import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../accounts.dart';
import '../../generated/intl/messages.dart';
import '../../store.dart';
import '../utils.dart';

class SyncStatusWidget extends StatefulWidget {
  SyncStatusState createState() => SyncStatusState();
}

class SyncStatusState extends State<SyncStatusWidget> {
  var display = 0;

  String getSyncText(int syncedHeight) {
    final s = S.of(context);
    final latestHeight = syncStatus.latestHeight;

    if (syncStatus.paused) return s.syncPaused;
    if (syncStatus.isSynced) {
      final sh = syncStatus.syncedHeight;
      final timestamp = sh.timestamp;
      final ts = timeago.format(toDate(timestamp));
      return '${sh.height} - $ts';
    }

    final remaining = syncStatus.eta.remaining ?? 0;
    final percent = syncStatus.eta.progress ?? 0;

    switch (display) {
      case 0:
        return '$syncedHeight / $latestHeight';
      case 1:
        final m = syncStatus.isRescan ? s.rescan : s.catchup;
        return '$m $percent %';
      case 2:
        return '$remaining...';
      case 3:
        return '${syncStatus.eta.timeRemaining}';
    }
    throw Exception('Unreachable');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final syncedHeight = syncStatus.syncedHeight;
    final text = getSyncText(syncedHeight.height);
    final syncing = syncStatus.syncing;
    final syncStyle = syncing
        ? t.textTheme.bodySmall!
        : t.textTheme.bodyMedium!.apply(color: t.primaryColor);
    final Widget inner = GestureDetector(
        onTap: _onSync,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
                color: t.colorScheme.surface,
                padding: EdgeInsets.all(8),
                child: Text(text, style: syncStyle))));
    final value = syncStatus.eta.progress?.let((x) => x.toDouble() / 100.0);
    return Observer(builder: (context) {
      aaSequence.syncProgressSeqno;

      return SizedBox(
        height: 50,
        child: Stack(
          children: <Widget>[
            if (value != null)
              SizedBox.expand(
                child: LinearProgressIndicator(
                  value: value,
                ),
              ),
            Center(child: inner),
          ],
        ),
      );
    });
  }

  _onSync() {
    if (syncStatus.syncing) {
      setState(() {
        display = (display + 1) % 4;
      });
    } else {
      Future(() async {
        syncStatus.setPause(false);
        aaSequence.onSyncProgressChanged();
        await syncStatus.sync(true);
      });
    }
  }
}
