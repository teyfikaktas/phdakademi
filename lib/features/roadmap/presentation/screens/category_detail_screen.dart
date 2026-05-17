import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:phd_akademi/features/roadmap/presentation/screens/roadmap_video.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../video/presentation/screens/video_player.dart';
import '../../data/models/roadmap_category.dart';
import '../../data/models/roadmap_level.dart';
import '../../data/models/roadmap_step.dart';

class CategoryDetailScreen extends StatefulWidget {
  final RoadmapCategory category;

  const CategoryDetailScreen({
    Key? key,
    required this.category,

  }) : super(key: key);

  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _isLoading = false;
  late RoadmapCategory _category;
  UserEntity? _currentUser; // User bilgisi için
  bool _isUserLoading = true;
  // Arama
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  // Collapse durumları
  Map<int, bool> _levelCollapsed = {};

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _loadUserData(); // User verisini yükle

    // Arama listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Başlangıçta tüm levels açık
    for (final level in _category.levels) {
      _levelCollapsed[level.id] = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _loadUserData() async {
    setState(() => _isUserLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _currentUser = null;
          _isUserLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _currentUser = UserEntity.fromJson(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('User load error: $e');
      setState(() => _currentUser = null);
    } finally {
      setState(() => _isUserLoading = false);
    }
  }
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_category.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
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
    final filteredLevels = _getFilteredLevels();

    if (filteredLevels.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsView(isDark);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader(theme, isDark)),

        // Progress Card
        SliverToBoxAdapter(child: _buildProgressCard(theme, isDark)),

        // Search Bar
        if (_showSearch)
          SliverToBoxAdapter(child: _buildSearchBar(theme, isDark)),

        // Levels
        ...filteredLevels.map((level) => _buildLevelSection(level, theme, isDark)),

        // Bottom padding
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildNoResultsView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Arama sonucu bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '"$_searchQuery" için sonuç yok',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.all(_isMobile ? 16 : 24),
      padding: EdgeInsets.all(_isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1E40AF), Color(0xFF3B82F6)]
              : [Color(0xFF0066FF), Color(0xFF00D4FF)],
        ),
        borderRadius: BorderRadius.circular(_isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: _isMobile ? 24 : 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _category.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_category.totalLevelsCount} Aşama',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_category.description.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              _category.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: _isMobile ? 14 : 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, bool isDark) {
    final progress = _category.totalStepsCount > 0
        ? _category.completedStepsCount / _category.totalStepsCount
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 24, vertical: 8),
      padding: EdgeInsets.all(_isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Genel İlerleme',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: _isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.grey[800]
                  : Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_category.completedStepsCount} / ${_category.totalStepsCount} adım tamamlandı',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              if (_category.inProgressStepsCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_category.inProgressStepsCount} devam ediyor',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 24, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Aşama veya adım ara...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              onPressed: () => _searchController.clear(),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: 32, height: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(RoadmapLevel level, ThemeData theme, bool isDark) {
    final isCollapsed = _levelCollapsed[level.id] ?? false;
    final filteredSteps = _getFilteredSteps(level);

    return SliverMainAxisGroup(
      slivers: [
        // Level Header
        SliverToBoxAdapter(
          child: _buildLevelHeader(level, theme, isDark),
        ),
        // Steps (sadece açık ise)
        if (!isCollapsed)
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final step = filteredSteps[index];
                return _buildStepCard(step, theme, isDark);
              },
              childCount: filteredSteps.length,
            ),
          ),
      ],
    );
  }

  Widget _buildLevelHeader(RoadmapLevel level, ThemeData theme, bool isDark) {
    final isCollapsed = _levelCollapsed[level.id] ?? false;
    final filteredSteps = _getFilteredSteps(level);

    return Container(
      margin: EdgeInsets.only(
        left: _isMobile ? 16 : 24,
        right: _isMobile ? 16 : 24,
        top: 16,
        bottom: 8,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _getLevelBorderColor(level, theme),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => _toggleLevelCollapse(level.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(_isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getLevelColors(level, isDark),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Level numarası
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: level.isCompleted
                      ? Icon(Icons.check_rounded, color: Colors.green[600], size: 20)
                      : Center(
                    child: Text(
                      '${level.order}',
                      style: TextStyle(
                        color: _getLevelNumberColor(level, theme),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Level bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (level.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          level.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: _isMobile ? 13 : 14,
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${level.completedStepsCount}/${level.totalStepsCount} adım',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty && filteredSteps.length != level.totalStepsCount) ...[
                            Text(
                              ' • ${filteredSteps.length} eşleşme',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              level.statusText,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Progress circle
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: level.completionPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(width: 8),
                // Collapse icon
                AnimatedRotation(
                  turns: isCollapsed ? -0.5 : 0,
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.8),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(RoadmapStep step, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(
        left: _isMobile ? 24 : 32,
        right: _isMobile ? 16 : 24,
        bottom: 8,
        top: 4,
      ),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getStepBorderColor(step, theme, isDark),
          ),
        ),
        child: InkWell(
          onTap: () => _handleStepTap(step),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(_isMobile ? 16 : 18),
            child: Column(
              children: [
                Row(
                  children: [
                    // Step icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStepColor(step, theme),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStepIcon(step),
                        color: _getStepIconColor(step, isDark),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Step info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        step.displayTitle,
                                        style: TextStyle(
                                          fontSize: _isMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: _getStepTextColor(step, theme),
                                          decoration: step.status == 'completed'
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    // ✅ VİDEO İKONU - HER ADIM İÇİN GÖRÜNÜR
                                    SizedBox(width: 8),
                                    step.hasVideo
                                        ? InkWell(
                                      onTap: () => _openVideoPlayerR(step),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFF4081),
                                              Color(0xFFE91E63),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFFFF4081).withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.play_circle_filled_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Video',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                        : Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_circle_filled_rounded,
                                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Video',
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              _buildStatusBadge(step, theme),
                              // ✅ ÖĞRETMEN YORUMU VARSA İKON GÖSTERİN
                              if (step.hasTeacherFeedback) ...[
                                SizedBox(width: 8),
                                Icon(
                                  Icons.school_rounded,
                                  color: Colors.green[600],
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          if (step.hasDescription) ...[
                            SizedBox(height: 4),
                            Html(
                              data: step.description,
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(12),
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                "p": Style(margin: Margins.zero),
                                "strong": Style(fontWeight: FontWeight.bold),
                                "em": Style(fontStyle: FontStyle.italic),
                                "span": Style(),
                              },
                            ),
                          ],
                          SizedBox(height: 4),
                          Text(
                            step.statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusTextColor(step, theme),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (step.status != 'completed')
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                  ],
                ),

                // ✅ ÖĞRETMEN YORUMU BÖLÜMÜ - HEM COMPLETED HEM IN_PROGRESS İÇİN
                if ((step.status == 'completed' || step.status == 'in_progress') && step.hasTeacherFeedback) ...[
                  SizedBox(height: 16),
                  _buildTeacherFeedbackSection(step, theme, isDark),
                ],

                // Günlük ilerleme bölümü
                if (step.status == 'in_progress' && (_currentUser?.hasActivePackage ?? false)) ...[
                  SizedBox(height: 16),
                  _buildDailyProgressSection(step, theme, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _openVideoPlayerR(RoadmapStep step) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoadmapVideoPage(step: step),
        ),

    );
  }  Widget _buildTeacherFeedbackSection(RoadmapStep step, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, size: 16, color: Colors.green[600]),
              SizedBox(width: 6),
              Text(
                'En Son Öğretmen Dönütü',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              Spacer(),
              if (step.teacherFeedbackDate != null)
                Text(
                  _formatDate(step.teacherFeedbackDate!),
                  style: TextStyle(fontSize: 11, color: Colors.green[600]),
                ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Text(
              step.teacherFeedback ?? '',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 8),
          // Tüm dönütleri görmek için buton
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showStepComments(step),
              icon: Icon(Icons.visibility_rounded, size: 14),
              label: Text('Tüm Dönütleri Gör', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[600],
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ TARIH FORMATLAMA HELPER METODU
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else if (difference < 7) {
      return '$difference gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  // CategoryDetailScreen sınıfının içine bu metodu ekleyin:

  Widget _buildDailyProgressSection(RoadmapStep step, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Günlük İlerleme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (step.canAddDailyComment == false)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Günlük ilerlemeniz kaydedildi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.done, color: Colors.white, size: 18),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDailyCommentDialog(step),
                icon: Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  'İlerleme Ekle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          SizedBox(height: 12),
          Row(
            children: [
              if (step.status == 'in_progress')
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompleteStepDialog(step),
                    icon: Icon(Icons.check, size: 18),
                    label: Text(
                      'Adımı Tamamla',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (step.status == 'in_progress') SizedBox(width: 12),
              Expanded(
                flex: step.status == 'in_progress' ? 1 : 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showStepComments(step),
                  icon: Icon(Icons.history, size: 18),
                  label: Text(
                    'Geçmiş',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    side: BorderSide(
                      color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildStatusBadge(RoadmapStep step, ThemeData theme) {
    Color color = _getStepColor(step, theme);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        step.statusDisplayText,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ===== HELPER METHODS =====

  List<RoadmapLevel> _getFilteredLevels() {
    if (_searchQuery.isEmpty) return _category.sortedLevels;

    return _category.sortedLevels.where((level) {
      if (level.title.toLowerCase().contains(_searchQuery) ||
          level.description.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      return level.steps.any((step) =>
      step.title.toLowerCase().contains(_searchQuery) ||
          step.description.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  List<RoadmapStep> _getFilteredSteps(RoadmapLevel level) {
    if (_searchQuery.isEmpty) return level.steps;

    return level.steps.where((step) =>
    step.title.toLowerCase().contains(_searchQuery) ||
        step.description.toLowerCase().contains(_searchQuery)).toList();
  }

  void _toggleLevelCollapse(int levelId) {
    setState(() {
      _levelCollapsed[levelId] = !(_levelCollapsed[levelId] ?? false);
    });
  }

  void _updateStep(RoadmapStep updatedStep) {
    setState(() {
      _category = _category.updateStep(updatedStep);
    });
  }

  // Renk helper metodları
  List<Color> _getLevelColors(RoadmapLevel level, bool isDark) {
    if (level.isCompleted) {
      return isDark ? [Color(0xFF16A34A), Color(0xFF22C55E)] : [Color(0xFF059669), Color(0xFF10B981)];
    } else if (level.hasInProgress) {
      return isDark ? [Color(0xFFEA580C), Color(0xFFF97316)] : [Color(0xFFDC2626), Color(0xFFEF4444)];
    } else {
      return isDark ? [Color(0xFF1E40AF), Color(0xFF3B82F6)] : [Color(0xFF0066FF), Color(0xFF00D4FF)];
    }
  }

  Color _getLevelBorderColor(RoadmapLevel level, ThemeData theme) {
    if (level.isCompleted) return Colors.green.withOpacity(0.3);
    if (level.hasInProgress) return Colors.orange.withOpacity(0.3);
    return theme.colorScheme.primary.withOpacity(0.3);
  }

  Color _getLevelNumberColor(RoadmapLevel level, ThemeData theme) {
    if (level.isCompleted) return Colors.green[600]!;
    if (level.hasInProgress) return Colors.orange[600]!;
    return theme.colorScheme.primary;
  }

  Color _getStepBorderColor(RoadmapStep step, ThemeData theme, bool isDark) {
    switch (step.status) {
      case 'completed':
        return theme.colorScheme.primary.withOpacity(0.3);
      case 'in_progress':
        return Colors.orange.withOpacity(0.3);
      default:
        return isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    }
  }

  Color _getStepColor(RoadmapStep step, ThemeData theme) {
    switch (step.status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getStepIcon(RoadmapStep step) {
    switch (step.status) {
      case 'completed':
        return Icons.check_rounded;
      case 'in_progress':
        return Icons.play_circle_outline_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  Color _getStepIconColor(RoadmapStep step, bool isDark) {
    switch (step.status) {
      case 'completed':
      case 'in_progress':
        return Colors.white;
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  Color _getStepTextColor(RoadmapStep step, ThemeData theme) {
    switch (step.status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'in_progress':
        return Colors.orange;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  Color _getStatusTextColor(RoadmapStep step, ThemeData theme) {
    switch (step.status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ===== ACTION METHODS =====
  void _handleStepTap(RoadmapStep step) {
    final hasAccess = _currentUser?.hasActivePackage ?? true;

    if (!hasAccess) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: _isMobile ? MediaQuery.of(context).size.width * 0.9 : 420,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB800), Color(0xFFFFA000)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Başlık
                  Text(
                    'Üyelik Gerekli',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Açıklama
                  Text(
                    'Adımlarla etkileşim kurabilmek için sisteme üye olmanız gerekiyor. Şu anda önizleme modundasınız.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Özellikler
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Üyelik ile erişeceğiniz özellikler:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...[
                          'Birebir eğitim koçluğu',
                          'Adım adım takip sistemi',
                          'Yardımcı uygulamalar desteği',
                          'SOS uygulaması',
                          'Öğretmen ile etkileşim',
                          'Günlük ilerleme kaydetme',
                        ].map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            // Web sitesine yönlendir
                            try {
                              final Uri url = Uri.parse('https://phdakademi.com');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                context.showError('Web sitesi açılamadı');
                              }
                            }
                          },
                          icon: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            'Detaylı Bilgi',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Anladım',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;

    }

    // Normal işlemler
    if (step.canStart) {
      _showStartStepDialog(step);
    } else if (step.canComplete) {
      _showCompleteStepDialog(step);
    }
  }
  Future<void> _startStep(RoadmapStep step) async {
    if (!step.canStart || !mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/start-step'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'step_id': step.id,
          'category_id': _category.id,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          HapticFeedback.lightImpact();
          if (mounted) context.showSuccess('Adım başlatıldı!');
          _updateStep(step.copyWith(
            status: 'in_progress',
            isInProgress: true,
            startedAt: DateTime.now(),
            canAddDailyComment: true,
          ));
        } else {
          if (mounted) context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        if (mounted) context.showError('Sunucu hatası');
      }
    } catch (e) {
      if (mounted) context.showError('Bağlantı hatası');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markStepComplete(RoadmapStep step, {String? comment}) async {
    if (!step.canComplete || !mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) context.showError('Oturum süresi dolmuş');
        return;
      }

      final requestBody = <String, dynamic>{
        'step_id': step.id,
        'category_id': _category.id,
      };
      if (comment != null && comment.isNotEmpty) {
        requestBody['comment'] = comment;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/complete-step'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          HapticFeedback.lightImpact();
          if (mounted) {
            context.showSuccess(comment != null && comment.isNotEmpty
                ? 'Adım yorumunuzla birlikte tamamlandı!'
                : 'Adım tamamlandı!');
          }
          _updateStep(step.copyWith(
            status: 'completed',
            isCompleted: true,
            isInProgress: false,
            completedAt: DateTime.now(),
            canAddDailyComment: false,
          ));
        } else {
          if (mounted) context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        if (mounted) context.showError('Sunucu hatası');
      }
    } catch (e) {
      if (mounted) context.showError('Bağlantı hatası');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDailyComment(RoadmapStep step, String comment) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/add-daily-comment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'step_id': step.id,
          'comment': comment,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          HapticFeedback.lightImpact();
          if (mounted) context.showSuccess('Günlük ilerlemeniz kaydedildi!');
          _updateStep(step.copyWith(canAddDailyComment: false));
        } else {
          if (mounted) context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        if (mounted) context.showError('Sunucu hatası');
      }
    } catch (e) {
      if (mounted) context.showError('Bağlantı hatası');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showStepComments(RoadmapStep step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/step-comments?step_id=${step.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) _showCommentsDialog(step, data['data']);
        } else {
          if (mounted) context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        if (mounted) context.showError('Sunucu hatası');
      }
    } catch (e) {
      if (mounted) context.showError('Bağlantı hatası');
    }
  }

  // ===== DIALOG METHODS =====

  void _showStartStepDialog(RoadmapStep step) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Adımı Başlat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${step.title} adımını başlatmak istiyor musunuz?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (step.hasDescription) ...[
                SizedBox(height: 20),
                Text(
                  'Adım Detayı:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Html(
                    data: step.fullContent,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: isDark ? Colors.white : Colors.black87,
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
                      "span": Style(
                        // Span elementleri için de stilleri uygula
                      ),
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startStep(step);
            },
            icon: Icon(Icons.play_arrow, size: 18, color: Colors.white),
            label: Text(
              'Başlat',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showCompleteStepDialog(RoadmapStep step) {
    final TextEditingController commentController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Adımı Tamamla',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${step.title} adımını tamamladınız mı?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),

              // ✅ Adım detayını HTML olarak göster
              if (step.hasDescription) ...[
                SizedBox(height: 20),
                Text(
                  'Adım Detayı:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Html(
                    data: step.fullContent,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                        color: isDark ? Colors.white : Colors.black87,
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
                      "span": Style(
                        // Span elementleri için özel stil
                      ),
                    },
                  ),
                ),
              ],

              SizedBox(height: 20),
              Text(
                'Yorumunuz (Opsiyonel):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Bu adımı tamamlarken neler öğrendiniz?',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16),
                  filled: true,
                  fillColor: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _markStepComplete(step, comment: commentController.text.trim());
            },
            icon: Icon(Icons.check_circle, size: 18, color: Colors.white),
            label: Text(
              'Tamamla',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showDailyCommentDialog(RoadmapStep step) {
    final TextEditingController commentController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_note, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Günlük İlerleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${step.title} adımında bugün neler yaptınız?',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Bugünkü İlerlemeleriniz:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 4,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Örnek: Bugün 2 saat çalıştım, X konusunu öğrendim...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                  ),
                ),
                contentPadding: EdgeInsets.all(16),
                filled: true,
                fillColor: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final comment = commentController.text.trim();

              // ✅ VALIDATION - Boş yorum kontrolü
              if (comment.isEmpty) {
                context.showError('Lütfen bir yorum yazın');
                return;
              }

              // ✅ Dialog'u kapat ve API call yap
              Navigator.pop(context);
              _addDailyComment(step, comment);
            },
            icon: Icon(Icons.save, size: 18, color: Colors.white),
            label: Text(
              'Kaydet',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }// CategoryDetailScreen'de sadece _showCommentsDialog metodunu değiştirin:

  void _showCommentsDialog(RoadmapStep step, List<dynamic> comments) {
    // Öğretmen ve öğrenci yorumlarını ayır
    final teacherComments = comments.where((c) => c['is_teacher_feedback'] == true).toList();
    final studentComments = comments.where((c) => c['is_teacher_feedback'] != true).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Yorum Geçmişi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: comments.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 64,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz yorum eklenmemiş',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ÖĞRETMEN YORUMLARI - EN ÜSTTE
                if (teacherComments.isNotEmpty) ...[
                  ...teacherComments.map((comment) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.school,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Öğretmen Geri Bildirimi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            Spacer(),
                            Text(
                              comment['formatted_date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF2A2A2A) : Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                            ),
                          ),
                          child: Text(
                            comment['comment'],
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  // Ayırıcı
                  if (studentComments.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: isDark ? Color(0xFF333333) : Color(0xFFE5E5E5),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Öğrenci Yorumları',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                  ],
                ],

                // ✅ ÖĞRENCİ YORUMLARI
                ...studentComments.map((comment) {
                  final isCompleted = comment['status'] == 'completed';
                  final statusColor = isCompleted ? Colors.blue : Color(0xFFEF4444);

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isCompleted ? Icons.check_circle : Icons.schedule,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              comment['formatted_date'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCompleted ? 'Tamamlandı' : 'Devam Ediyor',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          comment['comment'],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }}