import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
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
                              _buildStatusBadge(step, theme),
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
                                "p": Style(
                                  margin: Margins.zero,
                                ),
                                "strong": Style(
                                  fontWeight: FontWeight.bold,
                                ),
                                "em": Style(
                                  fontStyle: FontStyle.italic,
                                ),
                                "span": Style(
                                  // Span elementleri için stil
                                ),
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
                // Günlük ilerleme bölümü
                if (step.status == 'in_progress') ...[
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

  Widget _buildDailyProgressSection(RoadmapStep step, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]?.withOpacity(0.3) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              SizedBox(width: 6),
              Text(
                'Günlük İlerleme',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (step.canAddDailyComment == false)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Günlük ilerlemeniz kaydedildi',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text('✓', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDailyCommentDialog(step),
                icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text('İlerleme Ekle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          SizedBox(height: 8),
          Row(
            children: [
              if (step.status == 'in_progress')
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompleteStepDialog(step),
                    icon: Icon(Icons.check_rounded, size: 16),
                    label: Text('Adımı Tamamla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              if (step.status == 'in_progress') SizedBox(width: 8),
              Expanded(
                flex: step.status == 'in_progress' ? 1 : 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showStepComments(step),
                  icon: Icon(Icons.history_rounded, size: 16),
                  label: Text('Geçmiş', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                    side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.play_circle, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Adımı Başlat')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${step.title} adımını başlatmak istiyor musunuz?'),
              if (step.hasDescription) ...[
                SizedBox(height: 16),
                Text(
                  'Adım Detayı:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Html(
                    data: step.fullContent,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
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
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startStep(step);
            },
            icon: Icon(Icons.play_arrow),
            label: Text('Başlat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteStepDialog(RoadmapStep step) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Adımı Tamamla')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${step.title} adımını tamamladınız mı?'),

              // ✅ Adım detayını HTML olarak göster
              if (step.hasDescription) ...[
                SizedBox(height: 16),
                Text(
                  'Adım Detayı:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Html(
                    data: step.fullContent,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
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
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Bu adımı tamamlarken neler öğrendiniz?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _markStepComplete(step, comment: commentController.text.trim());
            },
            icon: Icon(Icons.check_circle),
            label: Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  void _showDailyCommentDialog(RoadmapStep step) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.today, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('Günlük İlerleme')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${step.title} adımında bugün neler yaptınız?'),
            SizedBox(height: 16),
            Text(
              'Bugünkü İlerlemeleriniz:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Örnek: Bugün 2 saat çalıştım, X konusunu öğrendim...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final comment = commentController.text.trim();
              if (comment.isEmpty) {
                context.showError('Lütfen bir yorum yazın');
                return;
              }
              Navigator.pop(context);
              _addDailyComment(step, comment);
            },
            icon: Icon(Icons.save),
            label: Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsDialog(RoadmapStep step, List<dynamic> comments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Yorum Geçmişi')),
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
                Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('Henüz yorum eklenmemiş', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
              : ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              final isCompleted = comment['status'] == 'completed';
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.today,
                          size: 16,
                          color: isCompleted ? Colors.green : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          comment['formatted_date'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green : Colors.blue,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(10),
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
                    SizedBox(height: 8),
                    Text(comment['comment'], style: TextStyle(fontSize: 14)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }
}