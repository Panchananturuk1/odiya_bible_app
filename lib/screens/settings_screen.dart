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
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSectionIcon(title),
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Display Settings':
        return Icons.display_settings_rounded;
      case 'Reading Settings':
        return Icons.auto_stories_rounded;
      case 'Audio Settings':
        return Icons.volume_up_rounded;
      case 'Account':
        return Icons.account_circle_rounded;
      case 'Data Management':
        return Icons.storage_rounded;
      case 'About':
        return Icons.info_rounded;
      default:
        return Icons.settings_rounded;
    }
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: children,
        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              inactiveThumbColor: Theme.of(context).colorScheme.outline,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              valueIndicatorColor: Theme.of(context).colorScheme.primary,
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
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
                
                // Get current audio speed from settings
                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                await audioProvider.playVerse(testVerse, audioSpeed: settingsProvider.audioSpeed);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test audio played successfully!'),
                      backgroundColor: Colors.green,
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
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
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