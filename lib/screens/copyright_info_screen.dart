import 'package:flutter/material.dart';

class CopyrightInfoScreen extends StatelessWidget {
  const CopyrightInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copyright Info'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}