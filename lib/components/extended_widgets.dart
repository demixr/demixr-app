import 'package:flutter/material.dart';
import 'package:intersperse/intersperse.dart';

class SpacedColumn extends Column {
  SpacedColumn({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    List<Widget> children = const <Widget>[],
    double spacing = 0,
  }) : super(
         children: children.intersperse(SizedBox(height: spacing)).toList(),
       );
}

class SpacedRow extends Row {
  SpacedRow({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    List<Widget> children = const <Widget>[],
    double spacing = 0,
  }) : super(children: children.intersperse(SizedBox(width: spacing)).toList());
}
