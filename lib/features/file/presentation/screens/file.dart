import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';

class FilesPage extends StatefulWidget {
  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<dynamic> teachers = [];
  bool _isLoading = true;

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
        Uri.parse('${ApiConstants.baseUrl}/files/teachers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

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
          'Dosyalar',
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
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Henüz dosya bulunamadı',
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
                          ? [Color(0xFF7C3AED), Color(0xFF8B5CF6)]
                          : [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.folder,
                      color: Colors.white,
                      size: 24,
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
                        'Dosyalar',
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
        builder: (context) => TeacherFilesPage(
          teacherSlug: teacher['slug'],
          teacherName: teacher['name'],
          teacherId: teacher['id'],
        ),
      ),
    );
  }
}

class TeacherFilesPage extends StatefulWidget {
  final String teacherSlug;
  final String teacherName;
  final int teacherId;

  const TeacherFilesPage({
    Key? key,
    required this.teacherSlug,
    required this.teacherName,
    required this.teacherId,
  }) : super(key: key);

  @override
  _TeacherFilesPageState createState() => _TeacherFilesPageState();
}

class _TeacherFilesPageState extends State<TeacherFilesPage> {
  List<dynamic> categories = [];
  bool _isLoading = true;

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
        Uri.parse('${ApiConstants.baseUrl}/files/teacher-categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'teacher_slug': widget.teacherSlug,
        }),
      );

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
          '${widget.teacherName} - Dosyalar',
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
    if (categories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Bu öğretmene ait dosya kategorisi bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, theme, isDark);
      },
    );
  }

  Widget _buildCategoryCard(dynamic category, ThemeData theme, bool isDark) {
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
          onTap: () => _navigateToCategoryFiles(category),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder_open,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    category['kategori_adi'] ?? 'İsimsiz Kategori',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
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

  void _navigateToCategoryFiles(dynamic category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFilesPage(
          teacherSlug: widget.teacherSlug,
          teacherName: widget.teacherName,
          categoryId: category['id'],
          categoryName: category['kategori_adi'],
        ),
      ),
    );
  }
}

class CategoryFilesPage extends StatefulWidget {
  final String teacherSlug;
  final String teacherName;
  final int categoryId;
  final String categoryName;

  const CategoryFilesPage({
    Key? key,
    required this.teacherSlug,
    required this.teacherName,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryFilesPageState createState() => _CategoryFilesPageState();
}

class _CategoryFilesPageState extends State<CategoryFilesPage> {
  List<dynamic> files = [];
  List<dynamic> subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryFiles();
  }

  Future<void> _fetchCategoryFiles() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/files/category-files'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'teacher_slug': widget.teacherSlug,
          'category_id': widget.categoryId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            files = data['data']['files'] ?? [];
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
    if (files.isEmpty && subCategories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Bu kategoride dosya bulunamadı',
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
          SizedBox(height: 24),
        ],
        if (files.isNotEmpty) ...[
          Text(
            'Dosyalar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...files.map((file) => _buildFileCard(file, theme, isDark)),
        ],
      ],
    );
  }

  Widget _buildSubCategoryCard(dynamic subCategory, ThemeData theme, bool isDark) {
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Color(0xFF10B981), Color(0xFF34D399)]
                          : [Color(0xFF059669), Color(0xFF10B981)],
                    ),
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
                  child: Text(
                    subCategory['kategori_adi'] ?? 'İsimsiz Alt Kategori',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
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

  Widget _buildFileCard(dynamic file, ThemeData theme, bool isDark) {
    final fileExtension = file['file_extension'] ?? '';
    final fileType = file['file_type'] ?? 'File';

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
          onTap: () => _downloadFile(file),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(fileType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileTypeIcon(fileType),
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
                        file['ad'] ?? 'İsimsiz Dosya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            fileType.toUpperCase(),
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (fileExtension.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              fileExtension.toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download_rounded,
                  size: 20,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'word':
        return Colors.blue;
      case 'excel':
        return Colors.green;
      case 'powerpoint':
        return Colors.orange;
      case 'image':
        return Colors.purple;
      case 'video':
        return Colors.pink;
      case 'audio':
        return Colors.teal;
      case 'archive':
        return Colors.brown;
      case 'text':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'word':
        return Icons.description;
      case 'excel':
        return Icons.table_chart;
      case 'powerpoint':
        return Icons.slideshow;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'archive':
        return Icons.archive;
      case 'text':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _navigateToSubCategory(dynamic subCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFilesPage(
          teacherSlug: widget.teacherSlug,
          teacherName: widget.teacherName,
          categoryId: subCategory['id'],
          categoryName: subCategory['kategori_adi'],
        ),
      ),
    );
  }

  Future<void> _downloadFile(dynamic file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      context.showError('Oturum süresi dolmuş');
      return;
    }

    _showLoadingDialog();

    try {
      final response = await _makeDownloadRequest(token, file['id']);
      _hideLoadingDialog();

      if (response.statusCode == 200) {
        await _handleSuccessfulResponse(response);
      } else {
        context.showError('Sunucu hatası');
      }
    } catch (e) {
      _hideLoadingDialog();
      context.showError('Bağlantı hatası: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(),
    );
  }

  Widget _buildLoadingDialog() {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Dosya hazırlanıyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<http.Response> _makeDownloadRequest(String token, dynamic fileId) async {
    return await http.post(
      Uri.parse('${ApiConstants.baseUrl}/files/download-link'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'file_id': fileId}),
    );
  }

  Future<void> _handleSuccessfulResponse(http.Response response) async {
    final data = json.decode(response.body);

    if (data['success'] != true) {
      context.showError(data['message'] ?? 'Dosya indirilemedi');
      return;
    }

    final fileUrl = data['data']['file_url'];
    await _openFileUrl(fileUrl);
  }

  Future<void> _openFileUrl(String fileUrl) async {
    try {
      // Android'de permission kontrolü
      if (Platform.isAndroid) {
        // Android 13+ için yeni izinler
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }
        if (await Permission.videos.isDenied) {
          await Permission.videos.request();
        }

        // Android 11+ için MANAGE_EXTERNAL_STORAGE izni
        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }

        // Eski Android sürümleri için
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }

      final uri = Uri.parse(fileUrl);
      print('Açılmaya çalışılan URL: $fileUrl'); // Debug için

      if (await canLaunchUrl(uri)) {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Dış uygulamada aç
        );

        if (launched) {
          context.showSuccess('Dosya başarıyla açıldı');
        } else {
          context.showError('Dosya açılamadı');
        }
      } else {
        // Alternatif olarak browser'da açmayı dene
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        if (!launched) {
          // Son çare olarak browser'da aç
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          context.showSuccess('Dosya tarayıcıda açıldı');
        } else {
          context.showSuccess('Dosya başarıyla açıldı');
        }
      }
    } catch (e) {
      print('Dosya açma hatası: $e'); // Debug için
      context.showError('Dosya açılırken hata oluştu: ${e.toString()}');
    }
  }}