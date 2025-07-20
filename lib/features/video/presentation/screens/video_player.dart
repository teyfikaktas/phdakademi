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

      print('🎬 Fetching video details for ID: ${widget.videoId}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/videos/get-link'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'video_id': widget.videoId.toString(), // String'e çeviriyoruz
        }),
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}'); // Debug için ekleyin

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Parsed Data: $data'); // Debug için ekleyin

        if (data['success'] == true) {
          setState(() {
            videoData = data['data'];
            videoLink = data['data']['video_link'];
            videoType = data['data']['video_type'];
          });

          print('🎥 Video Link: $videoLink');
          print('🎥 Video Type: $videoType');
          print('🎥 Video Data: $videoData'); // Debug için ekleyin

          // Video linkini aldıktan sonra player'ı başlat
          _initializePlayer();
        } else {
          print('❌ API Success=false: ${data['message']}');
          setState(() {
            _hasError = true;
            _errorMessage = data['message'] ?? 'Video yüklenemedi';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 422) {
        // Validation error - detaylı hata mesajı
        final data = json.decode(response.body);
        print('❌ Validation Error: $data');
        setState(() {
          _hasError = true;
          _errorMessage = 'Validation hatası: ${data['message'] ?? 'Geçersiz parametreler'}';
          _isLoading = false;
        });
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        setState(() {
          _hasError = true;
          _errorMessage = 'Sunucu hatası: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Exception in fetchVideoDetails: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }
  void _initializePlayer() async {
    if (videoLink == null) return;

    // YouTube videoları için external launcher
    if (videoType == 'youtube') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('🚀 Initializing video player with: $videoLink');

      // Video player controller oluştur
      _videoPlayerController = VideoPlayerController.network(videoLink!);

      // Video'yu initialize et
      await _videoPlayerController!.initialize();

      print('✅ Video controller initialized successfully');

      // Chewie controller oluştur
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: !kIsWeb,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        errorBuilder: (context, errorMessage) {
          print('🎬 Chewie Error: $errorMessage');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  'Video yüklenirken bir hata oluştu',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _launchInBrowser(videoLink!),
                  child: Text('Tarayıcıda Aç'),
                ),
              ],
            ),
          );
        },
      );

      print('✅ Chewie controller created successfully');

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('💥 Video player initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Video player başlatılamadı: $e';
        _isLoading = false;
      });
    }
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

    // Normal videolar için Chewie
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
  }

  Widget _buildVideoInfo(ThemeData theme, bool isDark) {
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