import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/repositories/roadmap_repository.dart';
import '../../data/models/roadmap_category.dart';
import '../../data/models/roadmap_step.dart';
import 'category_detail_screen.dart';

class RoadmapScreen extends StatefulWidget {
  @override
  _RoadmapScreenState createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isUserLoading = true;

  List<RoadmapCategory> _categories = [];
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final RoadmapRepository _repository = RoadmapRepository();
  UserEntity? _currentUser; // User bilgisi için

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadRoadmapData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  Future<void> _loadRoadmapData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _repository.getRoadmapCategories();
      setState(() {
        _categories = categories;
      });
      _startAnimations();
    } catch (e) {
      // Detaylı hata mesajı göster
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      context.showError(errorMessage);

      // Debug için detaylı log
      debugPrint('=== ROADMAP LOAD ERROR ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('========================');
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: _isLoading ? _buildLoadingState() : _buildBody(theme, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'Yol Haritası',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: _isMobile(context) ? 18 : 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded),
          onPressed: _loadRoadmapData,
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Yol haritası yükleniyor...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Henüz yol haritası yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Öğretmeniniz size bir program hazırladığında\nburada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoadmapData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(theme, isDark),
          ),
          SliverToBoxAdapter(
            child: _buildProgressOverview(theme, isDark),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final category = _categories[index];
                return AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    final delay = index * 0.1;
                    final animationValue = Curves.easeOutCubic.transform(
                        (_slideController.value - delay).clamp(0.0, 1.0)
                    );

                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - animationValue)),
                      child: Opacity(
                        opacity: animationValue,
                        child: _buildCategoryCard(category, theme, isDark),
                      ),
                    );
                  },
                );
              },
              childCount: _categories.length,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeController.value,
          child: Container(
            margin: EdgeInsets.all(_isMobile(context) ? 16 : 24),
            padding: EdgeInsets.all(_isMobile(context) ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Color(0xFF1E40AF), Color(0xFF3B82F6)]
                    : [Color(0xFF0066FF), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
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
                  width: _isMobile(context) ? 50 : 60,
                  height: _isMobile(context) ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: _isMobile(context) ? 24 : 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Öğrenme Yolculuğun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _isMobile(context) ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Adım adım hedefine ulaş',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: _isMobile(context) ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressOverview(ThemeData theme, bool isDark) {
    if (_categories.isEmpty) return SizedBox.shrink();

    // ✅ GÜNCELLEME: allSteps getter'ını kullan
    final totalSteps = _categories.fold<int>(
        0, (sum, category) => sum + category.totalStepsCount
    );
    final completedSteps = _categories.fold<int>(
        0, (sum, category) => sum + category.completedStepsCount
    );
    final inProgressSteps = _categories.fold<int>(
        0, (sum, category) => sum + category.inProgressStepsCount
    );
    final totalLevels = _categories.fold<int>(
        0, (sum, category) => sum + category.totalLevelsCount
    );

    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _fadeController.value)),
          child: Opacity(
            opacity: _fadeController.value,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: _isMobile(context) ? 16 : 24,
                vertical: 8,
              ),
              padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
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
                          fontSize: _isMobile(context) ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: _isMobile(context) ? 14 : 16,
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
                  // ✅ YENİ: Gelişmiş istatistikler
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedSteps / $totalSteps adım tamamlandı',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$totalLevels aşama • ${_categories.length} kategori',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (inProgressSteps > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 12,
                                color: Colors.orange[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$inProgressSteps devam ediyor',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(RoadmapCategory category, ThemeData theme, bool isDark) {
    // ✅ GÜNCELLEME: Levels yapısından progress hesapla
    final progress = category.totalStepsCount > 0
        ? category.completedStepsCount / category.totalStepsCount
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isMobile(context) ? 16 : 24,
        vertical: 8,
      ),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showCategoryDetails(category);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Kategori ikonu
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category.id).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(category.title),
                        color: _getCategoryColor(category.id),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Kategori bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: TextStyle(
                              fontSize: _isMobile(context) ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          // ✅ YENİ: Levels ve steps bilgisi
                          Row(
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${category.totalLevelsCount} aşama',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.assignment_outlined,
                                size: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${category.completedStepsCount}/${category.totalStepsCount} adım',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // İlerleme circle
                    SizedBox(
                      width: 45,
                      height: 45,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(category.id),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),

                // Açıklama
                if (category.description.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: 12),

                // Alt kısım: Progress bar ve durum bilgisi
                Column(
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(category.id),
                        ),
                        minHeight: 6,
                      ),
                    ),

                    SizedBox(height: 8),

                    // ✅ YENİ: Durum badge'leri
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getCategoryStatusColor(category, theme),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Progress steps badgesi
                        if (category.inProgressStepsCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${category.inProgressStepsCount} devam ediyor',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Completed badge
                        if (category.isCompleted)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 10,
                                  color: Colors.green[600],
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Tamamlandı',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ YENİ: Kategori durum rengi
  Color _getCategoryStatusColor(RoadmapCategory category, ThemeData theme) {
    if (category.isCompleted) return Colors.green[600]!;
    if (category.hasInProgress) return Colors.orange[600]!;
    if (category.isNotStarted) return Colors.grey[600]!;
    return theme.colorScheme.primary;
  }

  Color _getCategoryColor(int categoryId) {
    final colors = [
      Color(0xFF0066FF),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFFFF6B35),
      Color(0xFF0891B2),
      Color(0xFFEF4444),
    ];
    return colors[categoryId % colors.length];
  }

  IconData _getCategoryIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('reading') || titleLower.contains('okuma'))
      return Icons.menu_book_rounded;
    if (titleLower.contains('writing') || titleLower.contains('yazma'))
      return Icons.edit_rounded;
    if (titleLower.contains('listening') || titleLower.contains('dinleme'))
      return Icons.headphones_rounded;
    if (titleLower.contains('speaking') || titleLower.contains('konuşma'))
      return Icons.record_voice_over_rounded;
    if (titleLower.contains('grammar') || titleLower.contains('gramer'))
      return Icons.school_rounded;
    if (titleLower.contains('matematik') || titleLower.contains('math'))
      return Icons.calculate_rounded;
    if (titleLower.contains('ingilizce') || titleLower.contains('english'))
      return Icons.language_rounded;
    return Icons.star_rounded;
  }

  void _showCategoryDetails(RoadmapCategory category) {
    final hasAccess = _currentUser?.hasActivePackage ?? true;

    if (!hasAccess) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Önizleme Modu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text('Yol haritasını inceleyebilirsiniz.\nDetaylı etkileşim için ödeme gerekiyor.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tamam'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Normal detay ekranına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(category: category),
      ),
    );
  }
}