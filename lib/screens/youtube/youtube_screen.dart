import 'package:demixr_app/providers/demixing_provider.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DemixingScreen extends StatelessWidget {
  const DemixingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) =>
            YoutubeProvider(),
        child:  Container(
          margin: const EdgeInsets.all(10),
        ),
      ),
    );
  }
}
