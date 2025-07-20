import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:phd_akademi/features/video/presentation/screens/video_player.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';

class TeachersPage extends StatefulWidget {
  @override
  _TeachersPageState createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  List<dynamic> teachers = [];
  bool _isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/videos/teachers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Teachers Response Status: ${response.statusCode}');
      print('Teachers Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            teachers = data['data'] ?? [];
            _isLoading = false;
          });
        } else {
          context.showError(data['message'] ?? 'Bir hata oluştu');
          setState(() => _isLoading = false);
        }
      } else {
        context.showError('Sunucu hatası');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Hata: $e');
      context.showError('Bağlantı hatası');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Öğretmenler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(theme, isDark),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (teachers.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Henüz öğretmen bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTeachers,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return _buildTeacherCard(teacher, theme, isDark);
      },
    );
  }

  Widget _buildTeacherCard(dynamic teacher, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToTeacherDetail(teacher),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Color(0xFF1E40AF), Color(0xFF3B82F6)]
                          : [Color(0xFF0066FF), Color(0xFF00D4FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      teacher['name']?.substring(0, 1).toUpperCase() ?? 'Ö',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['name'] ?? 'İsimsiz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        teacher['email'] ?? 'E-posta yok',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTeacherDetail(dynamic teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDetailPage(
          teacherSlug: teacher['slug'],
          teacherName: teacher['name'],
          teacherId: teacher['id'],
        ),
      ),
    );
  }
}

class TeacherDetailPage extends StatefulWidget {
  final String teacherSlug;
  final String teacherName;
  final int teacherId;

  const TeacherDetailPage({
    Key? key,
    required this.teacherSlug,
    required this.teacherName,
    required this.teacherId,
  }) : super(key: key);

  @override
  _TeacherDetailPageState createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  List<dynamic> categories = [];
  bool _isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTeacherCategories();
  }

  Future<void> _fetchTeacherCategories() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/videos/teacher-categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'teacher_slug': widget.teacherSlug,
        }),
      );

      print('Categories Response Status: ${response.statusCode}');
      print('Categories Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            categories = data['data']['categories'] ?? [];
            _isLoading = false;
          });
        } else {
          context.showError(data['message'] ?? 'Bir hata oluştu');
          setState(() => _isLoading = false);
        }
      } else {
        context.showError('Sunucu hatası');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Hata: $e');
      context.showError('Bağlantı hatası');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.teacherName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(theme, isDark),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (categories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Bu öğretmene ait kategori bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTeacherCategories,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(theme, isDark),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, theme, isDark);
            },
            childCount: categories.length,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1E40AF), Color(0xFF3B82F6)]
              : [Color(0xFF0066FF), Color(0xFF00D4FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.teacherName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teacherName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${categories.length} Kategori',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToCategoryDetail(category),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['kategori_adi'] ?? 'İsimsiz Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (category['aciklama'] != null && category['aciklama'].isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          category['aciklama'],
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryDetail(dynamic category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryVideosPage(
          teacherSlug: widget.teacherSlug,
          teacherName: widget.teacherName,
          categoryId: category['id'],
          categoryName: category['kategori_adi'],
        ),
      ),
    );
  }
}

class CategoryVideosPage extends StatefulWidget {
  final String teacherSlug;
  final String teacherName;
  final int categoryId;
  final String categoryName;

  const CategoryVideosPage({
    Key? key,
    required this.teacherSlug,
    required this.teacherName,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryVideosPageState createState() => _CategoryVideosPageState();
}

class _CategoryVideosPageState extends State<CategoryVideosPage> {
  List<dynamic> videos = [];
  List<dynamic> subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryDetails();
  }

  Future<void> _fetchCategoryDetails() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/videos/category-details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'teacher_slug': widget.teacherSlug,
          'category_id': widget.categoryId,
        }),
      );

      print('Category Details Response Status: ${response.statusCode}');
      print('Category Details Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            videos = data['data']['videos'] ?? [];
            subCategories = data['data']['sub_categories'] ?? [];
            _isLoading = false;
          });
        } else {
          context.showError(data['message'] ?? 'Bir hata oluştu');
          setState(() => _isLoading = false);
        }
      } else {
        context.showError('Sunucu hatası');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Hata: $e');
      context.showError('Bağlantı hatası');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(theme, isDark),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (videos.isEmpty && subCategories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Bu kategoride içerik bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (subCategories.isNotEmpty) ...[
          Text(
            'Alt Kategoriler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...subCategories.map((subCat) => _buildSubCategoryCard(subCat, theme, isDark)),
          SizedBox(height: 20),
        ],
        if (videos.isNotEmpty) ...[
          Text(
            'Videolar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...videos.map((video) => _buildVideoCard(video, theme, isDark)),
        ],
      ],
    );
  }

// Bu methodları CategoryVideosPage class'ına ekle:

  Widget _buildSubCategoryCard(dynamic subCategory, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToSubCategory(subCategory),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subCategory['kategori_adi'] ?? 'Alt Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subCategory['aciklama'] != null &&
                          subCategory['aciklama'].toString().isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          subCategory['aciklama'],
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Alt kategoriye navigasyon methodu
  void _navigateToSubCategory(dynamic subCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryVideosPage(
          teacherSlug: widget.teacherSlug,
          teacherName: widget.teacherName,
          categoryId: subCategory['id'], // Alt kategori ID'sini kullan
          categoryName: subCategory['kategori_adi'] ?? 'Alt Kategori',
        ),
      ),
    );
  }
  Widget _buildVideoCard(dynamic video, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToVideoPlayer(video),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Video Thumbnail
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Video Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['ad'] ?? 'Video',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),

                      if (video['bilgi'] != null &&
                          video['bilgi'].toString().trim().isNotEmpty &&
                          video['bilgi'] != '.') ...[
                        Html(
                          data: video['bilgi'],
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontSize: FontSize(14),
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              maxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                            "p": Style(
                              margin: Margins.only(bottom: 4),
                            ),
                            "strong": Style(
                              fontWeight: FontWeight.bold,
                            ),
                            "em": Style(
                              fontStyle: FontStyle.italic,
                            ),
                          },
                        ),
                        SizedBox(height: 8),
                      ],

                      // Video metadata
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(video['created_at']),
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),
                Icon(
                  Icons.play_circle_fill,
                  color: theme.primaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Video player'a yönlendirme methodu - CategoryVideosPage'e ekle:
  void _navigateToVideoPlayer(dynamic video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoId: video['id'].toString(), // String'e çeviriyoruz
          videoTitle: video['ad'] ?? 'Video',
          teacherName: widget.teacherName,
        ),
      ),
    );
  }
// Tarih formatla methodu - CategoryVideosPage'e ekle:
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tarih yok';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} yıl önce';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} ay önce';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Tarih yok';
    }
  }}