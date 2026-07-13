import 'package:auto_size_text/auto_size_text.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/providers/model_provider.dart';
import 'package:demixr_app/screens/setup/components/model_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class ModelGroup extends StatelessWidget {
  final String title;
  final List<Model> models;
  final String imagePath;
  final String? infosUrl;
  final bool compact;

  const ModelGroup({
    required this.title,
    required this.imagePath,
    this.models = const [],
    this.infosUrl,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.read<ModelProvider>();

    List<Widget> modelCards = [
      for (var model in models)
        Semantics(
          button: true,
          label: 'Download ${model.name}',
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => modelProvider.downloadModel(
              model,
              onDone: () => Get.offAllNamed('/'),
            ),
            child: ModelCard(
              model: model,
              imagePath: imagePath,
              compact: compact,
            ),
          ),
        ),
    ];

    var children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
      ...modelCards,
    ];

    if (infosUrl != null) {
      children.add(
        AutoSizeText.rich(
          TextSpan(
            text: 'More information',
            style: TextStyle(
              color: ColorPalette.link,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(infosUrl!)),
          ),
          maxLines: 1,
        ),
      );
    }

    return SpacedColumn(spacing: compact ? 10 : 15, children: children);
  }
}
