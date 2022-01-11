import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/screens/setup/components/model_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ModelGroup extends StatelessWidget {
  final String title;
  final List<Model> models;
  final String imagePath;
  final String? infosUrl;

  const ModelGroup({
    required this.title,
    required this.imagePath,
    this.models = const [],
    this.infosUrl,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> modelCards = [
      for (var model in models)
        ModelCard(
          model: model,
          imagePath: imagePath,
        )
    ];

    var children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      ...modelCards,
    ];

    if (infosUrl != null) {
      children.add(
        RichText(
          text: TextSpan(
            text: 'More informations',
            style: TextStyle(
                color: Colors.blue.shade300,
                fontSize: 12,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => launch(infosUrl!),
          ),
        ),
      );
    }

    return SpacedColumn(
      spacing: 15,
      children: children,
    );
  }
}
