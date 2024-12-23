import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:tuple/tuple.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:warp/warp.dart';

import '../../accounts.dart';
import '../../appsettings.dart';
import '../../generated/intl/messages.dart';
import '../../store.dart';
import '../more/batch.dart';
import '../widgets.dart';
import '../utils.dart';

class RescanPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RescanState();
}

class RescanState extends State<RescanPage> with WithLoadingAnimation {
  late S s = S.of(context);
  final formKey = GlobalKey<FormBuilderState>();
  late int height;

  @override
  void initState() {
    super.initState();
    final activationHeight = warp.getActivationHeight(aa.coin);
    final accounts = warp.listAccounts(aa.coin);
    final minHeight = accounts.map((a) => a.birth).min() ?? activationHeight;
    height = minHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(s.rescan),
          actions: [
            if (!isMobile())
              IconButton(onPressed: download, icon: Icon(Icons.download)),
            if (!isMobile())
              IconButton(
                  onPressed: scanFromFile,
                  icon: Icon(Icons.run_circle_outlined)),
            IconButton(onPressed: rescan, icon: Icon(Icons.check)),
          ],
        ),
        body: wrapWithLoading(Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: FormBuilder(
                key: formKey,
                child: Column(children: [
                  HeightPicker(
                    height,
                    name: 'birth_height',
                    label: Text(s.rescanFrom),
                    onChanged: (h) => height = h!,
                  )
                ])))));
  }

  rescan() async {
    final form = formKey.currentState!;
    if (form.validate()) {
      form.save();
      final confirmed =
          await showConfirmDialog(context, s.confirm, s.confirmRescanFrom(height));
      if (confirmed) {
        Future(() async {
          await tryWarpFn(context, () => syncStatus.resetToHeight(height));
          aaSequence.onAccountDataChanged();
          aaSequence.onSyncProgressChanged();
          await syncStatus.sync(true);
        });
        GoRouter.of(context).pop();
      }
    }
  }

  download() async {
    final filename = isMobile()
        ? await getTemporaryPath('blockchain.dat')
        : await FilePicker.platform.saveFile(
            dialogTitle: 'save blockchain', fileName: 'blockchain.dat');
    logger.i("0");
    if (filename != null) {
      logger.i("1");
      await WarpSync.downloadWarpFile(
          aa.coin, coinSettings.warpUrl, coinSettings.warpHeight, filename);
    }
  }

  scanFromFile() async {
    final files = await FilePicker.platform
        .pickFiles(dialogTitle: 'load blockchain', type: FileType.any);
    if (files != null) {
      await load(() async {
        await WarpSync.syncFromFile(aa.coin, files.paths.first!);
      });
    }
  }
}

class RewindPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RewindState();
}

class RewindState extends State<RewindPage> {
  late final s = S.of(context);
  int? selected;
  bool calendar = true;
  DateTime? dateSelected;
  List<Tuple2<int, DateTime>>? checkpointDates;

  Future<List<Tuple2<int, DateTime>>> initialize() async {
    final checkpoints = await warp.listCheckpoints(aa.coin);
    return checkpoints
        .map((cp) => Tuple2(cp.height, toDate(cp.timestamp, dateOnly: true)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s.rewind), actions: [
        IconButton(onPressed: _onPurge, icon: Icon(Icons.cleaning_services)),
        calendar
            ? IconButton(
                onPressed: () => setState(() => calendar = false),
                icon: Icon(Icons.list))
            : IconButton(
                onPressed: () => setState(() => calendar = true),
                icon: Icon(Icons.event)),
        if (selected != null)
          IconButton(
              onPressed: () => rewind(checkpointDates),
              icon: Icon(Icons.check)),
      ]),
      body: FutureBuilder(
          future: initialize(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Jumbotron(snapshot.error.toString());
            if (!snapshot.hasData) return CircularProgressIndicator();
            final cpd = snapshot.data;
            if (cpd == null) return SizedBox.shrink();
            checkpointDates = cpd;
            final dates = cpd.map((cp) => cp.item2).toSet();
            return calendar
                ? CalendarDatePicker(
                    initialDate: dates.last,
                    firstDate: dates.first,
                    lastDate: dates.last,
                    onDateChanged: (dt) => _selectDate(cpd, dt),
                    selectableDayPredicate: (dt) => dates.contains(dt),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final cp = cpd[index];
                      final time = noteDateFormat.format(cp.item2);
                      return ListTile(
                        selected: index == selected,
                        title: Text(time),
                        trailing: Text(cp.item1.toString()),
                        onTap: () => setState(
                            () => selected = index != selected ? index : null),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: cpd.length);
          }),
    );
  }

  _selectDate(List<Tuple2<int, DateTime>> checkpointDates, DateTime dt) {
    selected = checkpointDates.indexWhere((d) => d.item2 == dt);
    setState(() {
      dateSelected = dt;
    });
  }

  _onPurge() async {
    final confirmed =
        await showConfirmDialog(context, s.confirm, s.checkpointPurgeConfirm);
    if (confirmed) {
      final minHeight = syncStatus.syncedHeight.height - 200;
      warp.purgeCheckpoints(aa.coin, minHeight.max(0));
      checkpointDates = await initialize();
      setState(() {});
    }
  }

  rewind(List<Tuple2<int, DateTime>>? checkpointDates) async {
    if (checkpointDates == null) return;
    final height = checkpointDates[selected!].item1;
    final confirmed =
        await showConfirmDialog(context, s.rewind, s.confirmRewind(height));
    if (!confirmed) return;
    Future(() async {
      await warp.rewindTo(aa.coin, height);
      aa.initialize();
      aaSequence.onAccountDataChanged();
      aaSequence.onSyncProgressChanged();
      await syncStatus.sync(true);
    });
    GoRouter.of(context).pop();
  }
}
