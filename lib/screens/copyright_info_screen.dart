import 'package:flutter/material.dart';

class CopyrightInfoScreen extends StatelessWidget {
  const CopyrightInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copyright Info'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audio Copyright Section
            const Text(
              'The Bible Audio is brought to you by:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/Davar-Audio.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Image not found');
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Indian Revised Version (IRV) Odia, CC-BY-SA-4.0, Bridge Connectivity Solutions (Text), Odia Indian Revised Audio Version, CC-BY-SA-4.0, Davar Partners International, 2021 (Audio)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // Text Copyright Section
            const Text(
              'The Bible Text is brought to you by:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/Bridge-connectivity.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Image not found');
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Indian Revised Version (IRV) - Odia (ଭାରତୀୟ ସଂଶୋଧିତ ସଂସ୍କରଣ - ଓଡ଼ିଆ), 2019 by Bridge Connectivity Solutions Pvt. Ltd. is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
          ],
=======
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
>>>>>>> 14a22d2102090697a1eb080781e2bbb4b4e709e9
        ),
      ),
    );
  }
}