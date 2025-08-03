import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../models/payment_model.dart';
import 'add_payment_page.dart';
import 'payment_detail_page.dart';

class OdemelerPage extends StatefulWidget {
  @override
  _OdemelerPageState createState() => _OdemelerPageState();
}

class _OdemelerPageState extends State<OdemelerPage>
    with TickerProviderStateMixin {
  List<dynamic> odemeler = [];
  Map<String, dynamic>? odemeSummary;
  bool _isLoading = true;
  bool _isTeacher = false;
  int currentPage = 1;
  int totalPages = 1;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkUserRole();
    _fetchOdemeler();
    _fetchOdemeSummary();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Responsive helpers
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;

  double _getHorizontalPadding(BuildContext context) {
    if (_isMobile(context)) return 16.0;
    if (_isTablet(context)) return 32.0;
    return 48.0;
  }

  double _getMaxWidth(BuildContext context) {
    if (_isMobile(context)) return double.infinity;
    if (_isTablet(context)) return 800;
    return 1200;
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getInt('user_role') ?? 0;
    setState(() {
      _isTeacher = userRole == 1;
    });
  }

  Future<void> _fetchOdemeler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/odemeler?page=$currentPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            if (currentPage == 1) {
              odemeler = data['data']['data'] ?? [];
            } else {
              odemeler.addAll(data['data']['data'] ?? []);
            }
            totalPages = data['data']['last_page'] ?? 1;
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

  Future<void> _fetchOdemeSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/odemeler/summary/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            odemeSummary = data['data'];
          });
        }
      }
    } catch (e) {
      print('Summary fetch error: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      currentPage = 1;
      odemeler.clear();
    });
    await _fetchOdemeler();
    await _fetchOdemeSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(theme, isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              const Color(0xFF0A0A0A),
              const Color(0xFF0F0F0F),
              const Color(0xFF1A1A1A),
            ]
                : [
              const Color(0xFFF8FAFC),
              const Color(0xFFFFFFFF),
              const Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Stack(
            children: [
              _buildBody(theme, isDark),
              if (_isLoading && odemeler.isEmpty) _buildLoadingOverlay(theme, isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isTeacher ? _buildFAB(theme, isDark) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      title: Text(
        'Ödemeler',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: _isMobile(context) ? 20 : 24,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: _isMobile(context) ? 20 : 24,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildFAB(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.scale(
          scale: _slideController.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _navigateToAddPayment();
            },
            backgroundColor: const Color(0xFFFFB800),
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: Text(
              'Ödeme Ekle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme, bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFFC947)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ödemeler yükleniyor...',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (odemeler.isEmpty && !_isLoading) {
      return _buildEmptyState(theme, isDark);
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _getMaxWidth(context)),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: _getHorizontalPadding(context),
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (odemeSummary != null) ...[
                    _buildSummaryCard(theme, isDark),
                    const SizedBox(height: 24),
                  ],
                  if (odemeler.isNotEmpty) ...[
                    _buildSectionTitle('Ödeme Geçmişi', theme),
                    const SizedBox(height: 16),
                  ],
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context)),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == odemeler.length && currentPage < totalPages) {
                      _loadMoreData();
                      return _buildLoadingItem(theme, isDark);
                    }
                    if (index >= odemeler.length) return null;

                    final odeme = odemeler[index];
                    return _buildOdemeCard(odeme, theme, isDark, index);
                  },
                  childCount: odemeler.length + (currentPage < totalPages ? 1 : 0),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeController.value,
          child: Text(
            title,
            style: TextStyle(
              fontSize: _isMobile(context) ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeController.value,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _isMobile(context) ? 120 : 140,
                    height: _isMobile(context) ? 120 : 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFB800).withOpacity(0.2),
                          const Color(0xFFFFC947).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(70),
                    ),
                    child: Icon(
                      Icons.payment_outlined,
                      size: _isMobile(context) ? 64 : 80,
                      color: const Color(0xFFFFB800),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isTeacher
                        ? 'Henüz ödeme kaydı bulunmuyor'
                        : 'Henüz ödeme eklememişsiniz',
                    style: TextStyle(
                      fontSize: _isMobile(context) ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isTeacher
                        ? 'Öğrencilerden ödeme geldiğinde burada görünecek'
                        : 'İlk ödemenizi ekleyerek öğretmeninize bildirin',
                    style: TextStyle(
                      fontSize: _isMobile(context) ? 14 : 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!_isTeacher) ...[
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB800).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _navigateToAddPayment();
                        },
                        icon: const Icon(Icons.add_rounded, size: 24),
                        label: const Text(
                          'İlk Ödemeyi Ekle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile(context) ? 24 : 32,
                            vertical: _isMobile(context) ? 16 : 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _fadeController.value)),
          child: Opacity(
            opacity: _fadeController.value,
            child: Container(
              padding: EdgeInsets.all(_isMobile(context) ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF3B82F6),
                    const Color(0xFF06B6D4),
                  ]
                      : [
                    const Color(0xFF0066FF),
                    const Color(0xFF00D4FF),
                    const Color(0xFF0099FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(_isMobile(context) ? 20 : 24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: _isMobile(context) ? 50 : 60,
                        height: _isMobile(context) ? 50 : 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: _isMobile(context) ? 28 : 32,
                        ),
                      ),
                      SizedBox(width: _isMobile(context) ? 16 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTeacher ? 'Öğretmen Özeti' : 'Ödeme Özeti',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _isMobile(context) ? 20 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isTeacher ? 'Tüm öğrenciler' : 'Kişisel durum',
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
                  SizedBox(height: _isMobile(context) ? 24 : 32),
                  if (_isTeacher) ..._buildTeacherSummary() else ..._buildStudentSummary(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTeacherSummary() {
    return [
      _buildSummaryRow(
        'Toplam Gelir',
        '₺${_formatMoney(odemeSummary!['toplam_odeme'])}',
        Icons.trending_up_rounded,
      ),
      SizedBox(height: _isMobile(context) ? 16 : 20),
      _buildSummaryRow(
        'Bekleyen Ödemeler',
        '₺${_formatMoney(odemeSummary!['bekleyen_odeme'])}',
        Icons.schedule_rounded,
      ),
      SizedBox(height: _isMobile(context) ? 16 : 20),
      Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Toplam Öğrenci',
              '${odemeSummary!['toplam_ogrenci']}',
              Icons.people_rounded,
            ),
          ),
          SizedBox(width: _isMobile(context) ? 16 : 20),
          Expanded(
            child: _buildSummaryItem(
              'Aktif Öğrenci',
              '${odemeSummary!['aktif_ogrenci']}',
              Icons.person_outline_rounded,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStudentSummary() {
    return [
      _buildSummaryRow(
        'Toplam Ödenen',
        '₺${_formatMoney(odemeSummary!['toplam_odeme'])}',
        Icons.check_circle_rounded,
      ),
      SizedBox(height: _isMobile(context) ? 16 : 20),
      _buildSummaryRow(
        'Bekleyen Ödemeler',
        '₺${_formatMoney(odemeSummary!['bekleyen_odeme'])}',
        Icons.schedule_rounded,
      ),
      if (odemeSummary!['sonraki_odeme_tarihi'] != null) ...[
        SizedBox(height: _isMobile(context) ? 16 : 20),
        _buildSummaryRow(
          'Sonraki Ödeme',
          _formatDate(odemeSummary!['sonraki_odeme_tarihi']),
          Icons.calendar_today_rounded,
        ),
      ],
    ];
  }

  Widget _buildSummaryRow(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _isMobile(context) ? 8 : 12,
        horizontal: _isMobile(context) ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_isMobile(context) ? 12 : 16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: _isMobile(context) ? 20 : 24,
            ),
          ),
          SizedBox(width: _isMobile(context) ? 12 : 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: _isMobile(context) ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: _isMobile(context) ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_isMobile(context) ? 12 : 16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: _isMobile(context) ? 24 : 28,
            ),
          ),
          SizedBox(height: _isMobile(context) ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: _isMobile(context) ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: _isMobile(context) ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOdemeCard(dynamic odeme, ThemeData theme, bool isDark, int index) {
    // Güvenli type casting
    final dynamic rawOdemeDurum = odeme['odeme_durum'];
    final int odeme_durum = rawOdemeDurum is int
        ? rawOdemeDurum
        : int.tryParse(rawOdemeDurum?.toString() ?? '0') ?? 0;

    final bool isApproved = odeme_durum == 1;
    final bool isPending = odeme_durum == 0;

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: _slideController.value),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: EdgeInsets.only(bottom: _isMobile(context) ? 12 : 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showOdemeDetail(odeme);
                      },
                      borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
                      child: Padding(
                        padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: _isMobile(context) ? 48 : 56,
                                  height: _isMobile(context) ? 48 : 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isApproved
                                          ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                          : isPending
                                          ? [const Color(0xFFFFB800), const Color(0xFFFFC947)]
                                          : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                                    ),
                                    borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isApproved
                                            ? const Color(0xFF10B981)
                                            : isPending
                                            ? const Color(0xFFFFB800)
                                            : const Color(0xFFEF4444)).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isApproved
                                        ? Icons.check_circle_rounded
                                        : isPending
                                        ? Icons.schedule_rounded
                                        : Icons.cancel_rounded,
                                    color: Colors.white,
                                    size: _isMobile(context) ? 24 : 28,
                                  ),
                                ),
                                SizedBox(width: _isMobile(context) ? 16 : 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '₺${_formatMoney(odeme['tutar'])}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _isMobile(context) ? 20 : 24,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const Spacer(),
                                          _buildStatusChip(odeme, isDark),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (_isTeacher && odeme['kullanici'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            odeme['kullanici']['adsoyad'] ?? odeme['kullanici']['name'] ?? 'İsimsiz',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: _isMobile(context) ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _isMobile(context) ? 16 : 20),
                            Container(
                              padding: EdgeInsets.all(_isMobile(context) ? 12 : 16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Açıklama',
                                    style: TextStyle(
                                      fontSize: _isMobile(context) ? 12 : 13,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    odeme['aciklama'] ?? 'Açıklama yok',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: _isMobile(context) ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: _isMobile(context) ? 12 : 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    size: _isMobile(context) ? 14 : 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(odeme['created_at']),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: _isMobile(context) ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                if (_isTeacher && isPending)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        _approvePayment(odeme);
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 18),
                                      label: const Text(
                                        'Onayla',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: _isMobile(context) ? 12 : 16,
                                          vertical: _isMobile(context) ? 8 : 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(dynamic odeme, bool isDark) {
    // Güvenli type casting
    final dynamic rawOdemeDurum = odeme['odeme_durum'];
    final int odeme_durum = rawOdemeDurum is int
        ? rawOdemeDurum
        : int.tryParse(rawOdemeDurum?.toString() ?? '0') ?? 0;

    final bool isApproved = odeme_durum == 1;
    final bool isPending = odeme_durum == 0;

    Color chipColor;
    String chipText;
    IconData chipIcon;

    if (isApproved) {
      chipColor = const Color(0xFF10B981);
      chipText = 'Onaylandı';
      chipIcon = Icons.check_circle_rounded;
    } else if (isPending) {
      chipColor = const Color(0xFFFFB800);
      chipText = 'Bekliyor';
      chipIcon = Icons.schedule_rounded;
    } else {
      chipColor = const Color(0xFFEF4444);
      chipText = 'Reddedildi';
      chipIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isMobile(context) ? 10 : 12,
        vertical: _isMobile(context) ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            color: chipColor,
            size: _isMobile(context) ? 14 : 16,
          ),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontSize: _isMobile(context) ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingItem(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: _isMobile(context) ? 12 : 16),
      padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Daha fazla ödeme yükleniyor...',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: _isMobile(context) ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadMoreData() {
    if (currentPage < totalPages && !_isLoading) {
      currentPage++;
      _fetchOdemeler();
    }
  }

  void _navigateToAddPayment() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => AddPaymentPage(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
      ),
    ).then((_) => _refreshData());
  }

  void _showOdemeDetail(dynamic odeme) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => PaymentDetailPage(
          odeme: odeme,
          isTeacher: _isTeacher,
        ),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
      ),
    ).then((_) => _refreshData());
  }

  Future<void> _approvePayment(dynamic odeme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/student/odemeler/${odeme['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tutar': odeme['tutar'],
          'aciklama': odeme['aciklama'],
          'odeme_durum': 1,
          'odemeonayi': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          HapticFeedback.lightImpact();
          context.showSuccess('Ödeme onaylandı');
          _refreshData();
        } else {
          context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        context.showError('Sunucu hatası');
      }
    } catch (e) {
      context.showError('Bağlantı hatası');
    }
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return '0';
    double value = double.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0);
  }

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
  }
}