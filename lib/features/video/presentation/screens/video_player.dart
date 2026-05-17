import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../core/constants/api_constants.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String teacherName;

  const VideoPlayerPage({
    Key? key,
    required this.videoId,
    required this.videoTitle,
    required this.teacherName,
  }) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Map<String, dynamic>? videoData;
  String? videoLink;
  String? videoType;

  @override
  void initState() {
    super.initState();
    _fetchVideoDetails();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

// _fetchVideoDetails metodunu güncelleyin:
  Future<void> _fetchVideoDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Oturum süresi dolmuş');
        return;
      }

      print('Fetching video details for ID: ${widget.videoId}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/videos/get-link'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'video_id': widget.videoId.toString(),
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            videoData = data['data'];
            videoType = data['data']['video_type'];

            // TÜM video türleri için direkt URL kullan - manuel işlem kaldırıldı
            videoLink = data['data']['video_link'].toString();
          });

          print('Video Link: $videoLink');
          print('Video Type: $videoType');

          _initializePlayer();
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = data['message'] ?? 'Video yüklenemedi';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Sunucu hatası: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }
  String _createSlug(String text) {
    print('🔤 Original text: $text');

    // Türkçe karakterleri İngilizce karşılıklarına çevir
    final turkishMap = {
      'ç': 'c', 'Ç': 'C',
      'ğ': 'g', 'Ğ': 'G',
      'ı': 'i', 'I': 'I',
      'İ': 'i', 'i': 'i',
      'ö': 'o', 'Ö': 'O',
      'ş': 's', 'Ş': 'S',
      'ü': 'u', 'Ü': 'U'
    };

    String result = text;
    turkishMap.forEach((turkish, english) {
      result = result.replaceAll(turkish, english);
    });

    print('🔤 After Turkish conversion: $result');

    result = result
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Özel karakterleri kaldır
        .replaceAll(RegExp(r'\s+'), '-') // Boşlukları tire ile değiştir
        .replaceAll(RegExp(r'-+'), '-') // Birden fazla tireyi tek tire yap
        .replaceAll(RegExp(r'^-|-$'), ''); // Başta ve sonda tire varsa kaldır

    print('🔤 Final slug: $result');
    return result;
  }

// VEYA daha basit bir çözüm - manuel slug:
  String _createSlugManual(String text) {
    // Manuel çeviriler
    final conversions = {
      'Bağlaçlar - Giriş': 'baglaclar-giris',
      'bağlaçlar - giriş': 'baglaclar-giris',
      'BAĞLAÇLAR - GİRİŞ': 'baglaclar-giris',
    };

    // Önce manuel çeviriyi kontrol et
    if (conversions.containsKey(text)) {
      return conversions[text]!;
    }

    // Yoksa otomatik çevir
    return text
        .toLowerCase()
        .replaceAll('ğ', 'g')
        .replaceAll('ç', 'c')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

// _initializePlayer metodunu güncelleyin:
  void _initializePlayer() async {
    if (videoLink == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video linki bulunamadı';
        _isLoading = false;
      });
      return;
    }

    if (videoType == 'youtube') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('Initializing video player with: $videoLink');
      print('Video type: $videoType');
      print('Platform: ${Platform.isAndroid ? "Android" : "iOS"}');

      // Android için özel header konfigürasyonu
      Map<String, String> headers = {
        'User-Agent': 'PHD-Akademi-App/1.0',
        'Accept': '*/*',  // Daha genel accept header
        'Accept-Encoding': 'identity',  // Compression sorunlarını önle
      };

      // Android için ek headers
      if (Platform.isAndroid) {
        headers.addAll({
          'Range': 'bytes=0-',  // Range request desteği
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        });
      }

      _videoPlayerController = VideoPlayerController.network(
        videoLink!,
        httpHeaders: headers,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,  // Android için ses karışımı
          allowBackgroundPlayback: false,
        ),
      );

      // Timeout ekle
      await _videoPlayerController!.initialize().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video yükleme zaman aşımı');
        },
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: !kIsWeb,
        allowMuting: true,
        showControls: true,
        // Android için özel ayarlar
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        errorBuilder: (context, errorMessage) {
          print('Chewie Error: $errorMessage');
          return _buildVideoError(errorMessage);
        },
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Video player initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Video başlatılamadı: $e';
        _isLoading = false;
      });
    }
  }
  Widget _buildVideoError(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              'Video yüklenirken hata oluştu',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            if (kDebugMode) ...[
              Text(
                'Error: $errorMessage',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              Text(
                'Video Link: $videoLink',
                style: TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchVideoDetails,
                  child: Text('Tekrar Dene'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _launchInBrowser(videoLink!),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Tarayıcıda Aç'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _launchInBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Tarayıcıda açılamadı');
      }
    } catch (e) {
      _showError('Video açılırken hata oluştu: $e');
    }
  }

  void _showError(String message) {
    print('🚨 Error: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.videoTitle,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Video yükleniyor...',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.white : Colors.black54,
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchVideoDetails,
                  child: Text('Tekrar Dene'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _launchInBrowser(videoLink!),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Tarayıcıda Aç'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Video Player Container
        Expanded(
          child: Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildVideoPlayer(),
            ),
          ),
        ),

        // Video Info
        Container(
          padding: EdgeInsets.all(16),
          child: _buildVideoInfo(theme, isDark),
        ),
      ],
    );
  }

// _buildVideoPlayer metodunu güncelleyin:
  Widget _buildVideoPlayer() {
    // YouTube videoları
    if (videoType == 'youtube') {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'YouTube Video',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _launchInBrowser(videoLink!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('YouTube\'da Aç'),
              ),
            ],
          ),
        ),
      );
    }

    // Tüm diğer videolar (legacy, upload) için Chewie player
    if (_chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }

    // Loading state
    return Container(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }  Widget _buildVideoInfo(ThemeData theme, bool isDark) {
    if (videoData == null) return SizedBox.shrink();

    final video = videoData!['video'];
    final teacher = videoData!['teacher'];
    final category = videoData!['category'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Title
        Text(
          video['ad'] ?? 'Video',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 8),

        // Teacher Info
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.cyan]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  teacher['name']?.substring(0, 1).toUpperCase() ?? 'Ö',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher['name'] ?? 'Öğretmen',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    category['kategori_adi'] ?? 'Kategori',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Video Description
        if (video['bilgi'] != null &&
            video['bilgi'].toString().trim().isNotEmpty &&
            video['bilgi'] != '.') ...[
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Html(
              data: video['bilgi'],
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(14),
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
                "p": Style(
                  margin: Margins.only(bottom: 8),
                ),
                "strong": Style(
                  fontWeight: FontWeight.bold,
                ),
                "em": Style(
                  fontStyle: FontStyle.italic,
                ),
                "ul": Style(
                  margin: Margins.only(left: 16, bottom: 8),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 4),
                ),
                "h1": Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(bottom: 8),
                ),
                "h2": Style(
                  fontSize: FontSize(16),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(bottom: 6),
                ),
                "h3": Style(
                  fontSize: FontSize(15),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(bottom: 4),
                ),
              },
            ),
          ),
        ],
      ],
    );
  }
}