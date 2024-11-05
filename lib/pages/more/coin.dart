import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../accounts.dart';
import '../../appsettings.dart';
import '../../generated/intl/messages.dart';
import '../../tablelist.dart';
import '../utils.dart';

class CoinControlPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SortSetting(
      child: Scaffold(
        appBar: AppBar(title: Text(s.notes)),
        body: Observer(
          builder: (context) {
            aaSequence.notesSeqno;

            return TableListPage(
              listKey: PageStorageKey('notes'),
              view: appSettings.noteView,
              items: aa.notes.items,
              metadata: TableListNoteMetadata(),
            );
          },
        ),
      ),
    );
  }
}

class TableListNoteMetadata extends TableListItemMetadata<Note> {
  @override
  List<Widget>? actions(BuildContext context) {
    return [
      IconButton(
          onPressed: inverseSelection, icon: Icon(MdiIcons.selectInverse)),
    ];
  }

  @override
  List<ColumnDefinition> columns(BuildContext context) {
    final s = S.of(context);
    return [
      ColumnDefinition(field: 'height', label: s.height, numeric: true),
      ColumnDefinition(label: s.confs, numeric: true),
      ColumnDefinition(field: 'timestamp', label: s.datetime),
      ColumnDefinition(field: 'value', label: s.amount),
    ];
  }

  @override
  Text? headerText(BuildContext context) {
    final s = S.of(context);
    final t = Theme.of(context);
    return Text(
      s.selectNotesToExcludeFromPayments,
      style: t.textTheme.bodyMedium,
    );
  }

  @override
  Widget toListTile(BuildContext context, int index, Note note, {void Function(void Function())? setState}) {
    final t = Theme.of(context);
    final excluded = note.excluded;
    final style = _noteStyle(t, note);
    final amountStyle = weightFromAmount(style, note.value);
    final nConfs = confirmations(note);
    final timestamp = humanizeDateTime(context, note.timestamp);
    return GestureDetector(
        onTap: () => _select(note),
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
            color: excluded
                ? t.primaryColor.withOpacity(0.5)
                : t.colorScheme.background,
            child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(children: [
                  Column(children: [
                    Text("${note.height}", style: t.textTheme.bodySmall),
                    Text("$nConfs", style: t.textTheme.bodyMedium),
                  ]),
                  Expanded(
                      child: Center(
                          child: Text("${note.value}", style: amountStyle))),
                  Text("$timestamp"),
                ]))));
  }

  @override
  DataRow toRow(BuildContext context, int index, Note note) {
    final t = Theme.of(context);
    final style = _noteStyle(t, note);
    final amountStyle = weightFromAmount(style, note.value);
    final nConfs = confirmations(note);

    return DataRow.byIndex(
      index: index,
      selected: note.excluded,
      color: MaterialStateColor.resolveWith((states) =>
          states.contains(MaterialState.selected)
              ? t.primaryColor.withOpacity(0.5)
              : t.colorScheme.background),
      cells: [
        DataCell(Text("${note.height}", style: style)),
        DataCell(Text("$nConfs", style: style)),
        DataCell(
            Text("${noteDateFormat.format(note.timestamp)}", style: style)),
        DataCell(Text(decimalFormat(note.value, 8), style: amountStyle)),
      ],
      onSelectChanged: (selected) => _select(note),
    );
  }

  @override
  void inverseSelection() {
    aa.notes.invert();
    _notifyChanged();
  }

  _select(Note note) {
    note.excluded = !note.excluded;
    aa.notes.exclude(note);
    _notifyChanged();
  }

  TextStyle _noteStyle(ThemeData t, Note note) {
    var style = t.textTheme.bodyMedium!;
    if (confirmations(note) < appSettings.anchorOffset)
      style = style.copyWith(color: style.color!.withOpacity(0.5));
    if (note.orchard) style = style.apply(color: t.primaryColor);
    return style;
  }

  int confirmations(Note note) => note.confirmations ?? -1;

  @override
  SortConfig2? sortBy(String field) {
    aa.notes.setSortOrder(field);
    _notifyChanged();
    return aa.notes.order;
  }
  
  @override
  Widget? header(BuildContext context) => null;

  _notifyChanged() {
    aaSequence.onNotesChanged();
  }
}
