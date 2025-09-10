import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class BibleBrainApiService {
  static final BibleBrainApiService _instance = BibleBrainApiService._internal();
  factory BibleBrainApiService() => _instance;
  BibleBrainApiService._internal();

  final Dio _dio = Dio();
  static const String _baseUrl = 'https://4.dbt.io/api';
  
  // Bible Brain API key - In production, this should be stored securely
  // Prefer runtime configuration via --dart-define to avoid hardcoding secrets.
  static const String _envApiKey = String.fromEnvironment('BIBLE_BRAIN_API_KEY', defaultValue: 'ef15d2b2-bed7-44aa-8626-605cc0c23609');
  static String _apiKey = _envApiKey; // Mutable so it can be provided later at runtime

  // Odia language and Bible version identifiers
  static const String _odiaLanguageId = 'ory'; // Odia language code
  static const String _envBibleId = String.fromEnvironment('BIBLE_BRAIN_BIBLE_ID', defaultValue: '');
  static String _defaultBibleId = _envBibleId.isNotEmpty ? _envBibleId : 'ORYWTC'; // Default Odia Bible ID
  
  // FilesetId for Odia audio - DBP4 uses FilesetId instead of bibleId/bookId/chapterId
  // Format: LLLVVV[CDMM-xxxxx] where LLL=language, VVV=version, C=collection, D=drama, MM=media
  // ORYWTCN1DA = Odia (ORY) + WTC version + New Testament (N) + Non-drama (1) + Digital Audio (DA)
  static const String _odiaAudioFilesetId = 'ORYWTCN1DA'; // NT audio 64kbps mp3 from WTC version
  static const String _odiaAudioFilesetDramaId = 'ORYWTCN2DA'; // NT audio drama
  static const String _odiaCompleteAudioFilesetId = 'ORYDPIN1DA'; // Alternative NT audio from DPI version
  static const String _odiaCompleteAudioFilesetDramaId = 'ORYDPIN2DA'; // Alternative NT drama
  static const String _odiaTextFilesetId = 'ORYWTC'; // Text-only fileset
  
  // Additional Odia filesets for coverage
  // ORYWTC = New Testament only, ORYDPI = Old Testament
  // Using correct Old Testament filesets for OT books and New Testament filesets for NT books
  static const String _odiaOldTestamentAudioFilesetId = 'ORYDPIO1DA'; // Old Testament audio
  static const String _odiaOldTestamentAudioFilesetDramaId = 'ORYDPIO2DA'; // Old Testament drama
  static const String _odiaCompleteCollectionAudioFilesetId = 'ORYDPIO1DA'; // Old Testament
  static const String _odiaCompleteCollectionAudioFilesetDramaId = 'ORYDPIO2DA'; // Old Testament drama

  // Book code sets to determine testament (USX/USFM 3-letter IDs)
  static const Set<String> _ntBookCodes = {
    'MAT','MRK','LUK','JHN','ACT','ROM','1CO','2CO','GAL','EPH','PHP','COL',
    '1TH','2TH','1TI','2TI','TIT','PHM','HEB','JAS','1PE','2PE','1JN','2JN','3JN','JUD','REV'
  };
  static const Set<String> _otBookCodes = {
    'GEN','EXO','LEV','NUM','DEU','JOS','JDG','RUT','1SA','2SA','1KI','2KI','1CH','2CH','EZR','NEH','EST','JOB','PSA','PRO','ECC','SNG','ISA','JER','LAM','EZK','DAN','HOS','JOL','AMO','OBA','JON','MIC','NAM','HAB','ZEP','HAG','ZEC','MAL'
  };

  bool _isNewTestamentBook(String bookId) {
    final id = bookId.toUpperCase();
    if (_ntBookCodes.contains(id)) return true;
    if (_otBookCodes.contains(id)) return false;
    // Fallback heuristic: default to NT if unknown and using WTC default Bible
    return id == 'MAT' || _defaultBibleId.contains('N');
  }

  // Returns candidate fileset IDs in priority order for the given bible/book
  List<String> _getAudioFilesetCandidates(String bibleId, String bookId) {
    final isNT = _isNewTestamentBook(bookId);
    // debugPrint('🔍 OT Debug: Book $bookId is NT: $isNT');

    if (isNT) {
      // Prefer DPI NT filesets first to match OT voice; fall back to WTC
      return <String>[
        _odiaCompleteAudioFilesetId,
        _odiaCompleteAudioFilesetDramaId,
        _odiaAudioFilesetId,
        _odiaAudioFilesetDramaId,
      ];
    } else {
      // debugPrint('🔍 OT Debug: Using OT filesets for $bookId');
      // debugPrint('🔍 OT Debug: OT candidates: $_odiaOldTestamentAudioFilesetId, $_odiaOldTestamentAudioFilesetDramaId');
      return <String>[
        _odiaOldTestamentAudioFilesetId,
        _odiaOldTestamentAudioFilesetDramaId,
      ];
    }
  }
  bool _isInitialized = false;
  int _retryCount = 3;
  Duration _retryDelay = const Duration(seconds: 2);

  // Sanitizes URLs that might be wrapped in quotes/backticks and/or have stray whitespace
  String _sanitizeUrl(String url) {
    String u = url.trim();
    // Remove wrapping backticks if present
    if (u.length >= 2 && u.startsWith('`') && u.endsWith('`')) {
      u = u.substring(1, u.length - 1).trim();
    }
    // Remove wrapping quotes if present
    if (u.length >= 2 && ((u.startsWith('"') && u.endsWith('"')) || (u.startsWith("'") && u.endsWith("'")))) {
      u = u.substring(1, u.length - 1).trim();
    }
    // Strip any remaining stray backticks
    u = u.replaceAll('`', '');
    // Prefer HTTPS to avoid mixed content issues on web
    if (u.startsWith('http://')) {
      u = 'https://' + u.substring(7);
    }
    return u;
  }
  // Allow setting API key at runtime once user provides it
  void setApiKey(String apiKey) {
    _apiKey = apiKey.trim();
  }

  String get apiKey => _apiKey;

  // Allow overriding default Bible ID (e.g., if a different Odia Bible is desired)
  void setDefaultBibleId(String bibleId) {
    final v = bibleId.trim();
    if (v.isNotEmpty) {
      _defaultBibleId = v;
    }
  }

  // Initialize the service with proper error handling
  Future<bool> initialize() async {
    try {
      _dio.options.baseUrl = _baseUrl;
      // On web, avoid setting Authorization header and non-simple headers to prevent CORS preflight failures
      if (kIsWeb) {
        _dio.options.headers = {
          'Accept': 'application/json',
        };
      } else {
        // Only attach Authorization header if we have an API key
        final headers = <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        };
        if (_apiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer $_apiKey';
        }
        _dio.options.headers = headers;
      }
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);
      _dio.options.sendTimeout = const Duration(seconds: 30);
      
      // Add interceptor for logging and error handling
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Inject API key handling and CORS-safe headers
          if (kIsWeb) {
            // Ensure Authorization header is not sent on web
            options.headers.remove('Authorization');
            // For GET requests, avoid sending Content-Type which can trigger preflight
            if (options.method.toUpperCase() == 'GET') {
              options.headers.remove('Content-Type');
            }
          }
          // Add API key and API version as query parameters for Bible Brain API host to maximize compatibility
          final host = options.uri.host;
          if ((host == '4.dbt.io' || host.endsWith('.dbt.io'))) {
            if (_apiKey.isNotEmpty) {
              options.queryParameters.putIfAbsent('key', () => _apiKey);
            }
            // DBP4 requires the 'v' parameter (set to 4)
            options.queryParameters.putIfAbsent('v', () => '4');
          }
          debugPrint('API Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('API Response: ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          handler.next(error);
        },
      ));
      
      // Test the connection (skip strict failure if API key not yet provided)
      await _testConnection();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Bible Brain API service: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Test API connection
  Future<void> _testConnection() async {
    // If API key is not set yet, skip test without throwing to allow app to continue
    if (_apiKey.isEmpty) {
      debugPrint('Bible Brain API key not set; skipping connection test.');
      return;
    }
    final response = await _dio.get('/bibles', 
      queryParameters: {'limit': 1}
    );
    if (response.statusCode != 200) {
      throw Exception('API connection test failed');
    }
  }
  
  // Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  // Get the appropriate FilesetId for audio based on Bible ID
  String _getAudioFilesetId(String bibleId) {
    // For now, use the predefined Odia FilesetIds
    // In a more complete implementation, this could be dynamic based on available filesets
    if (bibleId == 'ORYWTC' || bibleId.startsWith('ORY')) {
      return _odiaAudioFilesetId; // New Testament audio
    }
    // Fallback to New Testament audio FilesetId
    return _odiaAudioFilesetId;
  }

  // Generic retry wrapper for API calls
  Future<T> _retryApiCall<T>(Future<T> Function() apiCall) async {
    int attempt = 0;
    while (true) {
      try {
        return await apiCall();
      } catch (e) {
        attempt++;
        if (attempt >= _retryCount) rethrow;
        await Future.delayed(_retryDelay);
      }
    }
  }

  // Centralized logging for Dio exceptions to provide actionable diagnostics
  void _handleDioException(DioException e, String action) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? apiMessage;
    if (data is Map && data['data'] is String) {
      apiMessage = data['data'] as String;
    } else if (data is String) {
      apiMessage = data;
    }

    debugPrint(
        'Bible Brain API error while $action: status=${status ?? 'n/a'}, type=${e.type}, message=${e.message}${apiMessage != null ? ', apiMessage=$apiMessage' : ''}');

    if (status == 401 || status == 403) {
      debugPrint('Authentication/Authorization error while $action. Ensure a valid API key is supplied via --dart-define=BIBLE_BRAIN_API_KEY=YOUR_KEY or BibleBrainApiService.setApiKey().');
    } else if (status == 429) {
      debugPrint('Rate limit exceeded while $action. Please retry after some time.');
    } else if (status == 404) {
      debugPrint('Resource not found while $action. This may indicate the fileset/book/chapter is unavailable.');
    } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
      debugPrint('Timeout occurred while $action. Check network connectivity.');
    } else if (e.type == DioExceptionType.badCertificate) {
      debugPrint('Bad SSL certificate encountered while $action.');
    } else if (e.type == DioExceptionType.connectionError) {
      debugPrint('Network connectivity error while $action.');
    } else if (e.type == DioExceptionType.cancel) {
      debugPrint('Request was cancelled while $action.');
    } else if (e.type == DioExceptionType.badResponse) {
      debugPrint('Unexpected response while $action: ${e.response?.statusMessage}');
    }
  }

  // Diagnostic method to check available filesets for a specific book
  Future<List<Map<String, dynamic>>> getAvailableFilesetsForBook(String bibleId, String bookId) async {
    return await _retryApiCall(() async {
      try {
        debugPrint('🔍 OT AUDIO DEBUG: Checking available filesets for book $bookId in bible $bibleId');
        final response = await _dio.get('/bibles/$bibleId/filesets',
            queryParameters: {
              'book_id': bookId,
              'media': 'audio',
            });
        
        if (response.statusCode == 200) {
          final data = response.data;
          final filesets = List<Map<String, dynamic>>.from(data['data'] ?? []);
          debugPrint('🔍 OT AUDIO DEBUG: Found ${filesets.length} audio filesets for book $bookId');
          for (var fileset in filesets) {
            debugPrint('🔍 OT AUDIO DEBUG: Fileset: ${fileset['id']} - ${fileset['name']}');
          }
          return filesets;
        } else {
          debugPrint('🔍 OT AUDIO DEBUG: Failed to fetch filesets: ${response.statusCode}');
          return [];
        }
      } on DioException catch (e) {
        debugPrint('🔍 OT AUDIO DEBUG: Error fetching filesets: ${e.message}');
        return [];
      } catch (e) {
        debugPrint('🔍 OT AUDIO DEBUG: Error fetching filesets: $e');
        return [];
      }
    });
  }

  // Get available Odia Bible versions
  Future<List<Map<String, dynamic>>> getOdiaBibleVersions() async {
    return await _retryApiCall(() async {
      try {
        final response = await _dio.get('/bibles',
            queryParameters: {
              'language_code': _odiaLanguageId,
              'media': 'audio',
            });
        
        if (response.statusCode == 200) {
          final data = response.data;
          final versions = List<Map<String, dynamic>>.from(data['data'] ?? []);
          debugPrint('Found ${versions.length} Odia Bible versions');
          return versions;
        } else {
          throw Exception('Failed to fetch Bible versions: ${response.statusCode}');
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          throw Exception('Authentication failed. Please check API key.');
        } else if (e.response?.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Connection timeout. Please check your internet connection.');
        } else {
          throw Exception('Network error: ${e.message}');
        }
      } catch (e) {
        debugPrint('Error fetching Odia Bible versions: $e');
        throw Exception('Failed to fetch Bible versions: $e');
      }
    });
  }

  // Get books for a specific Bible version
  Future<List<Map<String, dynamic>>> getBooks(String bibleId) async {
    return await _retryApiCall(() async {
      try {
        final response = await _dio.get('/bibles/$bibleId/books');
        
        if (response.statusCode == 200) {
          final data = response.data;
          final books = List<Map<String, dynamic>>.from(data['data'] ?? []);
          debugPrint('Found ${books.length} books for Bible ID: $bibleId');
          return books;
        } else {
          throw Exception('Failed to fetch books: ${response.statusCode}');
        }
      } on DioException catch (e) {
        _handleDioException(e, 'fetching books');
        rethrow;
      } catch (e) {
        debugPrint('Error fetching books: $e');
        throw Exception('Failed to fetch books: $e');
      }
    });
  }

  // Get audio URL for a specific chapter using DBP4 FilesetId-based endpoints
  Future<String?> getChapterAudioUrl(String bibleId, String bookId, String chapterId) async {
    return await _retryApiCall(() async {
      try {
        // debugPrint('=== Bible Brain API: Getting Chapter Audio URL (DBP4) ===');
    // debugPrint('Bible ID: $bibleId');
    // debugPrint('Book ID: $bookId');
    // debugPrint('Chapter ID: $chapterId');
    // debugPrint('API Key present: ${_apiKey.isNotEmpty}');
    // debugPrint('🔍 OT AUDIO DEBUG: Checking if $bookId is Old Testament...');
        
        final candidates = _getAudioFilesetCandidates(bibleId, bookId);
        // debugPrint('Fileset candidates: $candidates');
    // debugPrint('Running on web: $kIsWeb');

    // Special debug for OT books
    final isOT = !_isNewTestamentBook(bookId);
    // if (isOT) {
    //   debugPrint('🔍 OT AUDIO DEBUG: This is an Old Testament book ($bookId)');
    //   debugPrint('🔍 OT AUDIO DEBUG: Will check these OT filesets: $candidates');
    // } else {
    //   debugPrint('🔍 OT AUDIO DEBUG: This is a New Testament book ($bookId)');
    // }

        for (final filesetId in candidates) {
          // Choose variants (prefer opus16/WebM on web for better compatibility; include MP3 off-web)
          final List<String> variants = kIsWeb
              ? <String>['${filesetId}-opus16', filesetId]
              : <String>[filesetId, '${filesetId}-opus16'];
          debugPrint('Variant order for $filesetId: $variants');
          for (final variant in variants) {
            final url = '/bibles/filesets/$variant/$bookId/$chapterId';
            debugPrint('Trying filesetId: $variant -> $_baseUrl$url');
            try {
              final response = await _dio.get(url);
              debugPrint('Response status for $variant: ${response.statusCode}');
              if (response.statusCode == 200) {
                final data = response.data;
                debugPrint('🔍 OT AUDIO DEBUG: Full API response for $variant: $data');
                if (data is! Map<String, dynamic>) {
                  debugPrint('🔍 OT AUDIO DEBUG: Unexpected response format for chapter audio URL - not a Map');
                  continue;
                }
                final responseData = data['data'];
                if (responseData == null) {
                  debugPrint('🔍 OT AUDIO DEBUG: No data field in response for chapter audio URL');
                  continue;
                }
                if (responseData is String) {
                  // e.g., error string from API
                  debugPrint('🔍 OT AUDIO DEBUG: API returned message for chapter audio URL: $responseData');
                  continue;
                }
                if (responseData is List && responseData.isNotEmpty) {
                  final firstAudio = responseData[0];
                  if (firstAudio is Map<String, dynamic>) {
                    final audioUrl = firstAudio['path'];
                    if (audioUrl != null && audioUrl.toString().isNotEmpty) {
                      final urlStr = audioUrl.toString();
                      final mimeGuess = firstAudio['mime_type'] ?? firstAudio['mimetype'] ?? firstAudio['type'];
                      debugPrint('API returned path: $urlStr mime: $mimeGuess');
                      if (kIsWeb && urlStr.toLowerCase().contains('.m3u8')) {
                        debugPrint('Detected HLS (.m3u8) for $variant – skipping on web and trying next');
                        continue;
                      }
                      final sanitized = _sanitizeUrl(urlStr);
                      debugPrint('Sanitized audio URL: $sanitized');
                      return sanitized;
                    }
                  }
                } else if (responseData is Map<String, dynamic>) {
                  final audioUrl = responseData['path'];
                  if (audioUrl != null && audioUrl.toString().isNotEmpty) {
                    final urlStr = audioUrl.toString();
                    final mimeGuess = responseData['mime_type'] ?? responseData['mimetype'] ?? responseData['type'];
                    debugPrint('API returned path: $urlStr mime: $mimeGuess');
                    if (kIsWeb && urlStr.toLowerCase().contains('.m3u8')) {
                      debugPrint('Detected HLS (.m3u8) for $variant – skipping on web and trying next');
                      continue;
                    }
                    final sanitized = _sanitizeUrl(urlStr);
                    debugPrint('Sanitized audio URL: $sanitized');
                    return sanitized;
                  }
                }
                debugPrint('No audio data found for $variant $bookId $chapterId – trying next candidate/variant');
                // try next variant or candidate
              } else if (response.statusCode == 404) {
                debugPrint('404 for $variant $bookId $chapterId – trying next');
                continue;
              }
            } on DioException catch (e) {
              final status = e.response?.statusCode;
              final body = e.response?.data;
              final msg = (body is Map && body['data'] is String) ? body['data'] as String : body?.toString();
              if (status == 404 || (msg != null && msg.contains('No Fileset Chapters Found'))) {
                debugPrint('Not found for $variant ($msg) – trying next');
                continue;
              }
              // Other network errors: log and try next candidate as well, unless auth
              if (status == 401 || status == 403) {
                _handleDioException(e, 'fetching chapter audio URL');
                rethrow;
              }
              debugPrint('Network error for $variant: ${e.message} – trying next');
              continue;
            }
          }
        }
        debugPrint('🔍 OT AUDIO DEBUG: No audio found for $bookId $chapterId in any candidate fileset');
        debugPrint('🔍 OT AUDIO DEBUG: This could indicate:');
        debugPrint('🔍 OT AUDIO DEBUG: 1. OT audio filesets are not available for this Bible');
        debugPrint('🔍 OT AUDIO DEBUG: 2. API key lacks access to OT audio');
        debugPrint('🔍 OT AUDIO DEBUG: 3. Chapter does not exist in OT audio filesets');
        return null;
      } catch (e) {
        debugPrint('🔍 OT AUDIO DEBUG: General error fetching chapter audio URL: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        throw Exception('Failed to fetch chapter audio URL: $e');
      }
    });
  }

  // Get verse-level audio timing data using DBP4 FilesetId-based endpoints
  Future<List<Map<String, dynamic>>> getVerseTimings(String bibleId, String bookId, String chapterId) async {
    return await _retryApiCall(() async {
      try {
        final candidates = _getAudioFilesetCandidates(bibleId, bookId);
        for (final filesetId in candidates) {
          final url = '/bibles/filesets/$filesetId/$bookId/$chapterId/timestamps';
          try {
            final response = await _dio.get(url);
            if (response.statusCode == 200) {
              final data = response.data;
              if (data is! Map<String, dynamic>) {
                debugPrint('Unexpected response format for verse timings');
                continue;
              }
              final responseData = data['data'];
              if (responseData == null) {
                debugPrint('No data field in response for verse timings');
                continue;
              }
              if (responseData is String) {
                debugPrint('API returned message for verse timings: $responseData');
                continue;
              }
              if (responseData is List) {
                final timings = List<Map<String, dynamic>>.from(responseData);
                debugPrint('Found ${timings.length} verse timings for $filesetId $bookId $chapterId');
                return timings;
              }
            }
          } on DioException catch (e) {
            final status = e.response?.statusCode;
            final body = e.response?.data;
            final msg = (body is Map && body['data'] is String) ? body['data'] as String : body?.toString();
            if (status == 404 || (msg != null && msg.contains('No Fileset Chapters Found'))) {
              debugPrint('Verse timings not found for $filesetId – trying next');
              continue;
            }
            if (status == 401 || status == 403) {
              _handleDioException(e, 'fetching verse timings');
              rethrow;
            }
            debugPrint('Network error getting verse timings for $filesetId: ${e.message} – trying next');
            continue;
          }
        }
        // If none available, return empty (non-fatal)
        return <Map<String, dynamic>>[];
      } catch (e) {
        debugPrint('Error fetching verse timings: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  // Download and cache audio file with progress tracking
  Future<String?> downloadAndCacheAudio(
    String audioUrl, 
    String bookName, 
    String chapterNumber, {
    Function(int received, int total)? onProgress,
  }) async {
    return await _retryApiCall(() async {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory('${directory.path}/audio_cache');
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }

        final fileName = '${bookName}_chapter_$chapterNumber.mp3';
        final filePath = '${audioDir.path}/$fileName';
        final file = File(filePath);

        // Check if file already exists
        if (await file.exists()) {
          debugPrint('Audio file already cached: $filePath');
          return filePath;
        }

        debugPrint('Downloading audio from: $audioUrl');
        
        // Download the file with progress tracking
        final response = await _dio.download(
          audioUrl, 
          filePath,
          onReceiveProgress: onProgress,
          options: Options(
            receiveTimeout: const Duration(minutes: 10), // Longer timeout for downloads
          ),
        );
        
        if (response.statusCode == 200) {
          final fileSize = await file.length();
          debugPrint('Audio downloaded successfully: $filePath (${fileSize} bytes)');
          return filePath;
        } else {
          throw Exception('Download failed with status: ${response.statusCode}');
        }
      } on DioException catch (e) {
        _handleDioException(e, 'downloading audio');
        rethrow;
      } catch (e) {
        debugPrint('Error downloading audio: $e');
        throw Exception('Failed to download audio: $e');
      }
    });
  }

  // Get default Bible ID for Odia
  String get defaultBibleId => _defaultBibleId;
  
  // Validate if audio URL is accessible
  Future<bool> validateAudioUrl(String audioUrl) async {
    try {
      final response = await _dio.head(audioUrl);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Audio URL validation failed: $e');
      return false;
    }
  }
  
  // Get audio file info without downloading
  Future<Map<String, dynamic>?> getAudioFileInfo(String audioUrl) async {
    try {
      final response = await _dio.head(audioUrl);
      if (response.statusCode == 200) {
        return {
          'contentLength': response.headers.value('content-length'),
          'contentType': response.headers.value('content-type'),
          'lastModified': response.headers.value('last-modified'),
        };
      }
      return null;
    } catch (e) {
       debugPrint('Error getting audio file info: $e');
       return null;
     }
   }

  // Check if audio file is cached
  Future<bool> isAudioCached(String bookName, String chapterNumber) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${bookName}_chapter_$chapterNumber.mp3';
      final filePath = '${directory.path}/audio_cache/$fileName';
      final file = File(filePath);
      final exists = await file.exists();
      if (exists) {
        // Verify file is not corrupted (has reasonable size)
        final fileSize = await file.length();
        if (fileSize < 1024) { // Less than 1KB is likely corrupted
          debugPrint('Cached file appears corrupted, removing: $filePath');
          await file.delete();
          return false;
        }
      }
      return exists;
    } catch (e) {
      debugPrint('Error checking cache: $e');
      return false;
    }
  }

  // Get cached audio file path
  Future<String?> getCachedAudioPath(String bookName, String chapterNumber) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${bookName}_chapter_$chapterNumber.mp3';
      final filePath = '${directory.path}/audio_cache/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        // Verify file integrity
        final fileSize = await file.length();
        if (fileSize < 1024) {
          debugPrint('Cached file appears corrupted, removing: $filePath');
          await file.delete();
          return null;
        }
        debugPrint('Found cached audio: $filePath (${fileSize} bytes)');
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached audio path: $e');
      return null;
    }
  }

  // Clear specific cached file
  Future<bool> clearCachedAudio(String bookName, String chapterNumber) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${bookName}_chapter_$chapterNumber.mp3';
      final filePath = '${directory.path}/audio_cache/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        debugPrint('Cleared cached audio: $filePath');
      }
      return true;
    } catch (e) {
      debugPrint('Error clearing cached audio: $e');
      return false;
    }
  }

  // Provide cache statistics (non-web only)
  Future<Map<String, dynamic>> getCacheStats() async {
    if (kIsWeb) {
      return {
        'fileCount': 0,
        'totalSize': 0,
        'files': <Map<String, dynamic>>[],
      };
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/audio_cache');
      if (!await cacheDir.exists()) {
        return {
          'fileCount': 0,
          'totalSize': 0,
          'files': <Map<String, dynamic>>[],
        };
      }
      int fileCount = 0;
      int totalSize = 0;
      final files = <Map<String, dynamic>>[];
      await for (final entity in cacheDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final size = stat.size;
            totalSize += size;
            fileCount += 1;
            final name = entity.uri.pathSegments.isNotEmpty
                ? entity.uri.pathSegments.last
                : entity.path.split(Platform.pathSeparator).last;
            files.add({
              'name': name,
              'size': size,
              'modified': stat.modified.toIso8601String(),
              'path': entity.path,
            });
          } catch (_) {}
        }
      }
      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'files': files,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {
        'fileCount': 0,
        'totalSize': 0,
        'files': <Map<String, dynamic>>[],
      };
    }
  }

  // Clear the entire audio cache directory contents (non-web only)
  Future<bool> clearAudioCache() async {
    if (kIsWeb) return false;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/audio_cache');
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: false, followLinks: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint('Failed deleting cache entity ${entity.path}: $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error clearing audio cache: $e');
      return false;
    }
  }

  // Remove corrupted or non-mp3 files from cache; returns number of files removed (non-web only)
  Future<int> cleanupCache() async {
    if (kIsWeb) return 0;
    int removed = 0;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/audio_cache');
      if (!await cacheDir.exists()) return 0;
      await for (final entity in cacheDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          try {
            final name = entity.uri.pathSegments.isNotEmpty
                ? entity.uri.pathSegments.last
                : entity.path.split(Platform.pathSeparator).last;
            final stat = await entity.stat();
            final size = stat.size;
            final isMp3 = name.toLowerCase().endsWith('.mp3');
            if (!isMp3 || size < 1024) {
              await entity.delete();
              removed++;
            }
          } catch (e) {
            debugPrint('Failed cleaning file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
    return removed;
  }
}