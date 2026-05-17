import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:phd_akademi/features/roadmap/data/models/roadmap_step.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class RoadmapVideoPage extends StatefulWidget {
  final RoadmapStep step;

  const RoadmapVideoPage({Key? key, required this.step}) : super(key: key);

  @override
  _RoadmapVideoPageState createState() => _RoadmapVideoPageState();
}

class _RoadmapVideoPageState extends State<RoadmapVideoPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final String baseVideoUrl = 'https://phdakademi.com/storage/steps/';
  String get fullVideoUrl => '$baseVideoUrl${widget.step.video}';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    // Video kontrolü - null veya boş mu?
    if (widget.step.video == null || widget.step.video!.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'video_not_ready';
        _isLoading = false;
      });
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.network(fullVideoUrl);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        errorBuilder: (context, errorMessage) {
          return _buildVideoNotReadyWidget();
        },
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _hasError = true;
        // 404 veya video bulunamadı hatalarını yakala
        if (e.toString().contains('404') ||
            e.toString().contains('File Not Found') ||
            e.toString().contains('not found') ||
            e.toString().contains('Failed to load video') ||
            e.toString().contains('HTTP 404')) {
          _errorMessage = 'video_not_ready';
        } else {
          _errorMessage = 'Video yüklenirken bir hata oluştu: $e';
        }
        _isLoading = false;
      });
    }
  }

  Widget _buildVideoNotReadyWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.black : Colors.grey[100],
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  '😊',
                  style: TextStyle(fontSize: 48),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Henüz Bu Adım İçin Video Eklenmemiş',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Hocamız yetiştirmeye çalışıyor,\nen kısa sürede yetişecektir!',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Sabırlı olduğunuz için teşekkürler! 🙏',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          widget.step.title, // Sadece adım başlığı
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16, // Daha küçük font
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
    // Loading durumu
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            SizedBox(height: 20),
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

    // Error durumu
    if (_hasError) {
      // Video henüz hazır değil
      if (_errorMessage == 'video_not_ready') {
        return _buildVideoNotReadyWidget();
      }

      // Diğer hatalar
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _initializePlayer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Tekrar Dene',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
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
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }

    return Container(
      height: 200,
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildStepInfo(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Title
        Text(
          widget.step.displayTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 8),

        // Status Badge ve kategori bilgisi simülasyonu
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.step.getStatusColor(context),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.step.order.toString(),
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
                    'Yol Haritası Adımı',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    widget.step.statusDisplayText,
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

        // Step Description/Content with Html rendering
        if (widget.step.hasText) ...[
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Html(
              data: widget.step.text!,
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
        ] else if (widget.step.hasDescription) ...[
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Html(
              data: widget.step.description,
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