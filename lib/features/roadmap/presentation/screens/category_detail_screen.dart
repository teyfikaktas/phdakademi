import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/roadmap_category.dart';
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

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  Future<void> _startStep(RoadmapStep step) async {
    if (!step.canStart) return;

    if (!mounted) return; // Mounted kontrolü ekle
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) context.showError('Oturum süresi dolmuş'); // Mounted kontrolü
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
          'category_id': widget.category.id,
        }),
      );

      if (!mounted) return; // API çağrısından sonra da kontrol et

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          HapticFeedback.lightImpact();
          if (mounted) context.showSuccess('Adım başlatıldı!');

          if (mounted) { // setState çağrısından önce kontrol et
            setState(() {
              final stepIndex = widget.category.steps.indexOf(step);
              if (stepIndex != -1) {
                widget.category.steps[stepIndex] = step.copyWith(
                  status: 'in_progress',
                  startedAt: DateTime.now(),
                  canAddDailyComment: true,
                );
              }
            });
          }
        } else {
          if (mounted) context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        if (mounted) context.showError('Sunucu hatası');
      }
    } catch (e) {
      if (mounted) context.showError('Bağlantı hatası');
    } finally {
      if (mounted) setState(() => _isLoading = false); // Finally bloğunda da kontrol et
    }
  }
  Future<void> _markStepComplete(RoadmapStep step, {String? comment}) async {
    if (!step.canComplete) return;

    if (!mounted) return;
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
        'category_id': widget.category.id,
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

          if (mounted) {
            setState(() {
              final stepIndex = widget.category.steps.indexOf(step);
              if (stepIndex != -1) {
                widget.category.steps[stepIndex] = step.copyWith(
                  status: 'completed',
                  completedAt: DateTime.now(),
                  canAddDailyComment: false,
                );
              }
            });
          }
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

          if (mounted) {
            setState(() {
              final stepIndex = widget.category.steps.indexOf(step);
              if (stepIndex != -1) {
                widget.category.steps[stepIndex] = step.copyWith(
                  canAddDailyComment: false,
                );
              }
            });
          }
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Stack(
        children: [
          _buildBody(theme, isDark),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        widget.category.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: _isMobile(context) ? 18 : 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pop(context),
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(theme, isDark),
        ),
        SliverToBoxAdapter(
          child: _buildProgressCard(theme, isDark),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final step = widget.category.steps[index];
              return AnimatedBuilder(
                animation: _listController,
                builder: (context, child) {
                  final delay = index * 0.05;
                  final animationValue = Curves.easeOutCubic.transform(
                      (_listController.value - delay).clamp(0.0, 1.0)
                  );

                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - animationValue)),
                    child: Opacity(
                      opacity: animationValue,
                      child: _buildStepCard(step, index, theme, isDark),
                    ),
                  );
                },
              );
            },
            childCount: widget.category.steps.length,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isMobile(context) ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.category.description.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Html(
                    data: widget.category.description,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: Colors.white.withOpacity(0.9),
                        fontSize: FontSize(_isMobile(context) ? 14 : 16),
                      ),
                      "p": Style(margin: Margins.zero),
                      "strong": Style(fontWeight: FontWeight.bold),
                      "em": Style(fontStyle: FontStyle.italic),
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(ThemeData theme, bool isDark) {
    final completedSteps = widget.category.steps.where((s) => s.status == 'completed').length;
    final inProgressSteps = widget.category.steps.where((s) => s.status == 'in_progress').length;
    final totalSteps = widget.category.steps.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeController.value)),
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
                        'İlerleme',
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
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$completedSteps / $totalSteps adım tamamlandı',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (inProgressSteps > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$inProgressSteps devam ediyor',
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepCard(RoadmapStep step, int index, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isMobile(context) ? 16 : 24,
        vertical: 6,
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
            padding: EdgeInsets.all(_isMobile(context) ? 16 : 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStepColor(step, theme, isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStepIcon(step),
                        color: _getStepIconColor(step, isDark),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
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
                                    fontSize: _isMobile(context) ? 14 : 16,
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
                                "p": Style(margin: Margins.zero),
                                "strong": Style(fontWeight: FontWeight.bold),
                                "em": Style(fontStyle: FontStyle.italic),
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

                // ✅ YENİ: Geliştirilmiş günlük ilerleme alanı
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

// ✅ YENİ: Ayrı widget olarak günlük ilerleme bölümü
  Widget _buildDailyProgressSection(RoadmapStep step, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[900]?.withOpacity(0.3)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
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

          // Durum mesajı veya buton
          if (step.canAddDailyComment == false)
          // Bugün eklendi durumu
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[600],
                    size: 18,
                  ),
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
                  Text(
                    '✓',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
          // Günlük ilerleme ekle butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDailyCommentDialog(step),
                icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(
                  'İlerleme Ekle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

          SizedBox(height: 8),

          // Alt butonlar - yan yana
          Row(
            children: [
              // Adımı Tamamla butonu - sadece in_progress'te göster
              if (step.status == 'in_progress')
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _completeStep(step),
                    icon: Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      'Adımı Tamamla',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),

              if (step.status == 'in_progress')
                SizedBox(width: 8),

              // Yorumları gör butonu
              Expanded(
                flex: step.status == 'in_progress' ? 1 : 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showStepComments(step),
                  icon: Icon(Icons.history_rounded, size: 16),
                  label: Text(
                    'Geçmiş',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
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
  void _handleStepTap(RoadmapStep step) {
    if (step.canStart) {
      _showStartStepDialog(step);
    } else if (step.canComplete) {
      _showCompleteStepDialog(step);
    }
  }
  void _completeStep(RoadmapStep step) {
    _showCompleteStepDialog(step);
  }
  Color _getStepBorderColor(RoadmapStep step, ThemeData theme, bool isDark) {
    switch (step.status) {
      case 'completed':
        return theme.colorScheme.primary.withOpacity(0.3);
      case 'in_progress':
        return Colors.orange.withOpacity(0.3);
      default:
        return isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05);
    }
  }

  Color _getStepColor(RoadmapStep step, ThemeData theme, bool isDark) {
    switch (step.status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'in_progress':
        return Colors.orange;
      default:
        return isDark ? Colors.grey[700]! : Colors.grey[300]!;
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

  Widget _buildStatusBadge(RoadmapStep step, ThemeData theme) {
    Color color = _getStepColor(step, theme, false);

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
              Text(
                '${step.title} adımını başlatmak istiyor musunuz?',
                style: TextStyle(fontSize: 16),
              ),
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
                      "p": Style(margin: Margins.only(bottom: 8)),
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
              Text(
                '${step.title} adımını tamamladınız mı?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

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
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Html(
                    data: step.fullContent,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14),
                      ),
                      "p": Style(margin: Margins.only(bottom: 8)),
                      "strong": Style(fontWeight: FontWeight.bold),
                      "em": Style(fontStyle: FontStyle.italic),
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
                  hintText: 'Bu adımı tamamlarken neler öğrendiniz? Zorlandığınız kısımlar var mıydı?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.all(12),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${step.title} adımında bugün neler yaptınız?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Her gün bu adımla ilgili ilerlemelerinizi paylaşabilirsiniz.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                  hintText: 'Örnek: Bugün 2 saat çalıştım, X konusunu öğrendim, Y kısmında zorlandım...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.all(12),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
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
                Icon(
                  Icons.comment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz yorum eklenmemiş',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
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
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.3),
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
                    Text(
                      comment['comment'],
                      style: TextStyle(fontSize: 14),
                    ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}