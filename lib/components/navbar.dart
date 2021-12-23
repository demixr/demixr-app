import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final List<Widget> extra;

  const NavBar({Key? key, this.extra = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            iconSize: 24,
            icon: const Icon(Icons.arrow_back),
            color: ColorPalette.onSurface,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ...extra
        ],
      ),
    );
  }
}
