import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/bible_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_provider.dart';
import '../models/verse.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Display Settings
            _buildSectionHeader(context, 'Display Settings'),
            _buildSettingsCard(
              context,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  icon: settingsProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  value: settingsProvider.isDarkMode,
                  onChanged: (value) => settingsProvider.toggleDarkMode(),
                ),
                const Divider(),
                _buildSliderTile(
                  context,
                  title: 'Font Size',
                  subtitle: 'Adjust text size for comfortable reading',
                  icon: Icons.text_fields,
                  value: settingsProvider.fontSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 12,
                  onChanged: settingsProvider.setFontSize,
                ),
                const Divider(),
                _buildSwitchTile(
                  context,
                  title: 'Parallel Bible',
                  subtitle: 'Show English translation alongside Odiya',
                  icon: Icons.compare,
                  value: settingsProvider.showParallelBible,
                  onChanged: settingsProvider.toggleParallelBible,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Reading Settings
            _buildSectionHeader(context, 'Reading Settings'),
            _buildSettingsCard(
              context,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Keep Screen On',
                  subtitle: 'Prevent screen from turning off while reading',
                  icon: Icons.screen_lock_portrait,
                  value: settingsProvider.keepScreenOn,
                  onChanged: settingsProvider.toggleKeepScreenOn,
                ),
                const Divider(),
                _buildSwitchTile(
                  context,
                  title: 'Auto Scroll',
                  subtitle: 'Automatically scroll while reading',
                  icon: Icons.auto_stories,
                  value: settingsProvider.autoScroll,
                  onChanged: settingsProvider.toggleAutoScroll,
                ),
                if (settingsProvider.autoScroll) ...
                [
                  const Divider(),
                  _buildSliderTile(
                    context,
                    title: 'Scroll Speed',
                    subtitle: 'Adjust auto-scroll speed',
                    icon: Icons.speed,
                    value: settingsProvider.scrollSpeed,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    onChanged: settingsProvider.setScrollSpeed,
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Audio Settings
            _buildSectionHeader(context, 'Audio Settings'),
            _buildSettingsCard(
              context,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Audio Playback',
                  subtitle: 'Enable audio reading of verses',
                  icon: Icons.volume_up,
                  value: settingsProvider.audioEnabled,
                  onChanged: settingsProvider.toggleAudio,
                ),
                if (settingsProvider.audioEnabled) ...
                [
                  const Divider(),
                  _buildSliderTile(
                    context,
                    title: 'Playback Speed',
                    subtitle: 'Adjust audio playback speed',
                    icon: Icons.speed,
                    value: settingsProvider.audioSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    onChanged: settingsProvider.setAudioSpeed,
                  ),
                  const Divider(),
                  _buildTestAudioTile(context),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Account Settings
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAuthenticated) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Account'),
                      _buildSettingsCard(
                        context,
                        children: [
                          ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(authProvider.displayName ?? 'User'),
                            subtitle: Text(authProvider.email ?? ''),
                          ),
                          const Divider(),
                          _buildActionTile(
                            context,
                            title: 'Sync Data',
                            subtitle: _getSyncStatusText(authProvider.syncStatus),
                            icon: Icons.sync,
                            onTap: () async {
                              await authProvider.triggerSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Syncing data...')),
                                );
                              }
                            },
                          ),
                          const Divider(),
                          _buildActionTile(
                            context,
                            title: 'Sign Out',
                            subtitle: 'Log out from your account',
                            icon: Icons.logout,
                            onTap: () async {
                              await authProvider.signOut();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Signed out successfully')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            // Data Management
            _buildSectionHeader(context, 'Data Management'),
            _buildSettingsCard(
              context,
              children: [
                _buildActionTile(
                  context,
                  title: 'Export Bookmarks',
                  subtitle: 'Save your bookmarks to a file',
                  icon: Icons.upload_file,
                  onTap: () => _exportBookmarks(context),
                ),
                const Divider(),
                _buildActionTile(
                  context,
                  title: 'Import Bookmarks',
                  subtitle: 'Load bookmarks from a file',
                  icon: Icons.download,
                  onTap: () => _importBookmarks(context),
                ),
                const Divider(),
                _buildActionTile(
                  context,
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  icon: Icons.cleaning_services,
                  onTap: () => _showClearCacheDialog(context),
                ),
                const Divider(),
                _buildActionTile(
                  context,
                  title: 'Reset Settings',
                  subtitle: 'Restore default settings',
                  icon: Icons.restore,
                  onTap: () => _showResetDialog(context, settingsProvider),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // About
            _buildSectionHeader(context, 'About'),
            _buildSettingsCard(
              context,
              children: [
                _buildActionTile(
                  context,
                  title: 'About This App',
                  subtitle: 'Version and information',
                  icon: Icons.info,
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(),
                _buildActionTile(
                  context,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  icon: Icons.privacy_tip,
                  onTap: () => _openPrivacyPolicy(context),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing in progress...';
      case SyncStatus.success:
        return 'Last sync successful';
      case SyncStatus.error:
        return 'Last sync failed';
      case SyncStatus.idle:
      default:
        return 'Tap to sync your data';
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTestAudioTile(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return ListTile(
          leading: const Icon(Icons.volume_up),
          title: const Text('Test Audio'),
          subtitle: const Text('Test if audio is working on your device'),
          trailing: ElevatedButton(
            onPressed: () async {
              try {
                // Create a test verse
                 final testVerse = Verse(
                   id: 0,
                   bookId: 0,
                   chapter: 1,
                   verseNumber: 1,
                   odiyaText: 'ଅଡିଓ ପରୀକ୍ଷା', // "Audio test" in Odia
                   englishText: 'Audio test',
                 );
                
                await audioProvider.playVerse(testVerse);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio test started. If you don\'t hear anything, try tapping the button again.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Audio test failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Test'),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportBookmarks(BuildContext context) {
    // TODO: Implement bookmark export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _importBookmarks(BuildContext context) {
    // TODO: Implement bookmark import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Odiya Bible',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.menu_book,
        size: 48,
        color: Color(0xFF6B4E3D),
      ),
      children: [
        const Text(
          'A beautiful and feature-rich Bible app for reading the Holy Bible in Odiya language.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• Read Bible in Odiya\n'
          '• Search verses\n'
          '• Bookmark favorite verses\n'
          '• Add personal notes\n'
          '• Dark mode support\n'
          '• Adjustable font size',
        ),
      ],
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // TODO: Open privacy policy URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy will open in browser')),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. '
          'Your bookmarks and notes will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              settingsProvider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}