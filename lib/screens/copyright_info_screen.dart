import 'package:flutter/material.dart';

class CopyrightInfoScreen extends StatelessWidget {
  const CopyrightInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copyright Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'The Bible Audio is brought to you by:',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const _LogoCard(
            assetPath: 'assets/Copyright/Davar-Audio.jpg',
            semanticLabel: 'Davar Partners International',
          ),
          const SizedBox(height: 12),
          const Text(
            'Indian Revised Version (IRV) Odia, CC-BY-SA-4.0, Bridge Connectivity Solutions (Text), Odia Indian Revised Audio Version, CC-BY-SA-4.0, Davar Partners International, 2021 (Audio)',
          ),

          const SizedBox(height: 24),

          Text(
            'The Bible Text is brought to you by:',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const _LogoCard(
            assetPath: 'assets/Copyright/Bridge-connectivity.jpg',
            semanticLabel: 'Bridge Connectivity Solutions',
          ),
          const SizedBox(height: 12),
          const Text(
            'Indian Revised Version (IRV) - Odia (ଇଣ୍ଡିୟାନ ରିୱାଇସ୍ଡ୍ ୱରସନ୍ - ଓଡିଆ), 2019 by Bridge Connectivity Solutions Pvt. Ltd. is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.',
          ),
        ],
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  const _LogoCard({required this.assetPath, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}