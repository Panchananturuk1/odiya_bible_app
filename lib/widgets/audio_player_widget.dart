import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_streaming_provider.dart';
import '../providers/bible_provider.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 80.0,
      end: 200.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioStreamingProvider, BibleProvider>(
      builder: (context, audioProvider, bibleProvider, child) {
        // Hide the player if audio provider is not initialized or not visible
        if (!audioProvider.isInitialized || !audioProvider.isVisible) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Container(
              height: _heightAnimation.value,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Main player controls
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Time display
                        Text(
                          '${audioProvider.currentPosition.inMinutes}:${(audioProvider.currentPosition.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        
                        // Progress bar
                        Expanded(
                          child: Slider(
                            value: audioProvider.totalDuration.inMilliseconds > 0
                                ? audioProvider.currentPosition.inMilliseconds / audioProvider.totalDuration.inMilliseconds
                                : 0.0,
                            onChanged: (value) {
                              final position = Duration(
                                milliseconds: (value * audioProvider.totalDuration.inMilliseconds).round(),
                              );
                              audioProvider.seek(position);
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Play/Pause button
                        IconButton(
                          icon: Icon(_getPlayPauseIcon(audioProvider.isPlaying)),
                          onPressed: () => _handlePlayPause(audioProvider),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Duration display
                        Text(
                          '${audioProvider.totalDuration.inMinutes}:${(audioProvider.totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Expand/Collapse button
                        IconButton(
                          icon: Icon(
                            audioProvider.isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                          onPressed: () {
                            audioProvider.toggleExpanded();
                            if (audioProvider.isExpanded) {
                              _animationController.forward();
                            } else {
                              _animationController.reverse();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Additional controls (when expanded)
                  if (audioProvider.isExpanded)
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Track title
                          Text(
                            _getTrackTitle(bibleProvider),
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Control buttons row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Previous verse
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                onPressed: () {
                                  // TODO: Implement previous verse functionality
                                },
                              ),
                              
                              // Rewind 10s
                              IconButton(
                                icon: const Icon(Icons.replay_10),
                                onPressed: () {
                                  final newPosition = audioProvider.currentPosition - const Duration(seconds: 10);
                                  audioProvider.seek(newPosition.isNegative ? Duration.zero : newPosition);
                                },
                              ),
                              
                              // Download button
                              _buildDownloadButton(audioProvider),
                              
                              // Forward 10s
                              IconButton(
                                icon: const Icon(Icons.forward_10),
                                onPressed: () {
                                  final newPosition = audioProvider.currentPosition + const Duration(seconds: 10);
                                  audioProvider.seek(newPosition > audioProvider.totalDuration ? audioProvider.totalDuration : newPosition);
                                },
                              ),
                              
                              // Next verse
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                onPressed: () {
                                  // TODO: Implement next verse functionality
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getPlayPauseIcon(bool isPlaying) {
    return isPlaying ? Icons.pause : Icons.play_arrow;
  }

  String _getTrackTitle(BibleProvider bibleProvider) {
    final audioProvider = context.read<AudioStreamingProvider>();
    if (audioProvider.currentBookId != null && audioProvider.currentChapter != null) {
      final currentBook = bibleProvider.currentBook;
      if (currentBook != null) {
        return '${currentBook.odiyaName} Chapter ${audioProvider.currentChapter}';
      }
    }

    final currentBook = bibleProvider.currentBook;
    final currentChapter = bibleProvider.currentChapter;

    if (currentBook != null) {
      return '${currentBook.odiyaName} Chapter $currentChapter';
    }

    return 'Audio Player';
  }

  void _handlePlayPause(AudioStreamingProvider audioProvider) {
    if (audioProvider.isPlaying) {
      audioProvider.pause();
    } else {
      audioProvider.play();
    }
  }

  Widget _buildDownloadButton(AudioStreamingProvider audioProvider) {
    return FutureBuilder<bool>(
      future: audioProvider.isChapterDownloaded(
        audioProvider.currentBookId ?? '',
        audioProvider.currentChapter ?? 1,
      ),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        
        return IconButton(
          icon: Icon(
            isDownloaded ? Icons.download_done : Icons.download,
            color: isDownloaded ? Colors.green : null,
          ),
          onPressed: isDownloaded
              ? null
              : () {
                  if (audioProvider.currentBookId != null && audioProvider.currentChapter != null) {
                    audioProvider.downloadChapter(
                      audioProvider.currentBookId!,
                      audioProvider.currentChapter!,
                    );
                  }
                },
        );
      },
    );
  }
}