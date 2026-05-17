import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phd_akademi/core/utils/snackbar_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../core/constants/api_constants.dart';
import '../auth/domain/entities/user_entity.dart';
import '../file/presentation/screens/file.dart';
import '../payment/screens/odemeler_page.dart';
import '../roadmap/presentation/screens/roadmap_screen.dart';
import '../video/presentation/screens/teacher_category.dart';

class DashboardScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;
  final UserEntity? userEntity;

  const DashboardScreen({
    Key? key,
    required this.onThemeChanged,
    required this.currentThemeMode,
    this.userEntity,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  UserEntity? _currentUser;
  bool _isLoading = false;

  late AnimationController _heroController;
  late AnimationController _cardsController;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });  }

  void _initAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardsController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // Responsive breakpoints
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  bool _isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  // Responsive values
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

  int _getStatusGridColumns(BuildContext context) {
    if (_isMobile(context)) return 2;
    if (_isTablet(context)) return 4;
    return 4;
  }

  int _getMenuGridColumns(BuildContext context) {
    if (_isMobile(context)) return 2;
    if (_isTablet(context)) return 3;
    return 4;
  }

  double _getHeroCardPadding(BuildContext context) {
    if (_isMobile(context)) return 20.0;
    if (_isTablet(context)) return 28.0;
    return 32.0;
  }

  double _getHeroTitleSize(BuildContext context) {
    if (_isMobile(context)) return 24.0;
    if (_isTablet(context)) return 28.0;
    return 32.0;
  }

  Future<void> _loadUserInfo() async {
    // Widget'tan gelen user varsa geçici olarak göster
    if (widget.userEntity != null) {
      setState(() {
        _currentUser = widget.userEntity;
      });
      _startAnimations();
    }

    // ⭐ HER ZAMAN API'DEN FRESH DATA ÇEK ⭐
    await _fetchUserFromServer();
  }

  void _startAnimations() {
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _fabController.forward();
    });
  }

  Future<void> _fetchUserFromServer() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _goToLogin();
        return;
      }

      print('🌐 Fetching fresh user data from API...');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 API Response Data: $data');

        if (data['success'] == true) {
          final userData = data['data'];
          print('👤 User Data: $userData');

          // Sadece current user'ı set et, cache yok
          setState(() {
            _currentUser = UserEntity.fromJson(userData);
          });

          print('✅ User loaded successfully: ${_currentUser!.name}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                // Force rebuild
              });
            }
          });
          _startAnimations();
        } else {
          print('❌ API Success false: ${data['message']}');
          _goToLogin();
        }
      } else {
        print('❌ API Error - Status: ${response.statusCode}, Body: ${response.body}');
        _goToLogin();
      }
    } catch (e) {
      print('💥 Fetch user error: $e');
      _goToLogin();
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => LoginScreen(),
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
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }

    await prefs.clear();
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return _buildLoadingScreen();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(theme, isDark),
      body: _buildBody(theme, isDark),
      floatingActionButton: _buildThemeToggle(isDark),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _isMobile(context) ? 80 : 100,
                height: _isMobile(context) ? 80 : 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00D4FF)],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bilgileriniz yükleniyor...',
                style: TextStyle(
                  fontSize: _isMobile(context) ? 16 : 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      title: Container(
        height: _isMobile(context) ? 40 : 48, // Boyut büyütüldü
        child: Image.asset(
          'assets/qrcode.png',
          fit: BoxFit.contain,
          // Hata durumunda fallback
          errorBuilder: (context, error, stackTrace) {
            print('Logo yüklenemedi: $error');
            return Text(
              'PhD Akademi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _isMobile(context) ? 20 : 24, // Yazı da büyütüldü
                color: theme.colorScheme.onSurface,
              ),
            );
          },
        ),
      ),
      centerTitle: false, // Sola hizalandı
      titleSpacing: _isMobile(context) ? 16 : 24, // Sol boşluk
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded),
          onPressed: _refreshUserData, // ← Bu fonksiyonu kullan
        ),
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            color: theme.colorScheme.error,
            size: _isMobile(context) ? 20 : 24,
          ),
          onPressed: _logout,
        ),
        SizedBox(width: _isMobile(context) ? 8 : 16),
      ],
    );
  }  Widget _buildBody(ThemeData theme, bool isDark) {
    return Container(
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
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUserData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _getMaxWidth(context)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getHorizontalPadding(context),
                        vertical: _isMobile(context) ? 16 : 24,
                      ),
                      child: Column(
                        children: [
                          _buildHeroCard(theme, isDark),
                          SizedBox(height: _isMobile(context) ? 20 : 32),

                          // Teacher card - responsive layout
                          if (!_currentUser!.isAdmin && _currentUser!.ogretmenAdi != null)
                            _buildTeacherCard(theme, isDark),
                          if (!_currentUser!.isAdmin && _currentUser!.ogretmenAdi != null)
                            SizedBox(height: _isMobile(context) ? 20 : 32),

                          // Status grid - responsive
                          _buildStatusGrid(theme, isDark),
                          SizedBox(height: _isMobile(context) ? 24 : 40),

                          // Menu grid - responsive
                          _buildMenuGrid(theme, isDark),

                          // Bottom padding for FAB
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// Refresh için de aynı fonksiyonu kullan
  Future<void> _refreshUserData() async {
    print('🔄 Refreshing user data...');
    await _fetchUserFromServer();
  }
  Widget _buildHeroCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _heroController.value)),
          child: Opacity(
            opacity: _heroController.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(_getHeroCardPadding(context)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isMobile(context) ? 20 : 24),
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
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: _isMobile(context) ? 15 : 20,
                    offset: Offset(0, _isMobile(context) ? 8 : 10),
                  ),
                ],
              ),
              child: _isDesktop(context)
                  ? _buildHeroCardDesktop(theme, isDark)
                  : _buildHeroCardMobile(theme, isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCardMobile(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade500,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _currentUser!.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Hoş geldin, ',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _currentUser!.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser!.email,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_currentUser!.daysRemaining != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentUser!.daysRemaining} gün kaldı',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_currentUser!.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCardDesktop(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade500,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _currentUser!.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Hoş geldin, ',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _currentUser!.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey.shade900,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.email,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_currentUser!.daysRemaining != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentUser!.daysRemaining} gün kaldı',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_currentUser!.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade500,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _cardsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardsController.value)),
          child: Opacity(
            opacity: _cardsController.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
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
                    blurRadius: _isMobile(context) ? 15 : 20,
                    offset: Offset(0, _isMobile(context) ? 6 : 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: _isMobile(context) ? 40 : 50,
                    height: _isMobile(context) ? 40 : 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(_isMobile(context) ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: _isMobile(context) ? 24 : 30,
                    ),
                  ),
                  SizedBox(width: _isMobile(context) ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eğitmeniniz',
                          style: TextStyle(
                            fontSize: _isMobile(context) ? 12 : 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentUser!.ogretmenAdi ?? 'Belirtilmemiş',
                          style: TextStyle(
                            fontSize: _isMobile(context) ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(_isMobile(context) ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_isMobile(context) ? 10 : 12),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: const Color(0xFF8B5CF6),
                      size: _isMobile(context) ? 16 : 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusGrid(ThemeData theme, bool isDark) {
    final statusItems = [
      StatusItem(
        title: 'Aktif',
        value: _currentUser!.isActive ? 'EVET' : 'HAYIR',
        color: _currentUser!.isActive ? Colors.green : Colors.red,
        icon: Icons.check_circle_rounded,
      ),
      StatusItem(
        title: 'SMS Doğrulama',
        value: _currentUser!.isSmsVerified ? 'TAMAM' : 'GEREKLİ',
        color: _currentUser!.isSmsVerified ? Colors.green : Colors.orange,
        icon: Icons.sms_rounded,
      ),
      StatusItem(
        title: 'Paket Durumu',
        value: _currentUser!.hasActivePackage ? 'AKTİF' : 'PASİF',
        color: _currentUser!.hasActivePackage ? Colors.green : Colors.red,
        icon: Icons.card_membership_rounded,
      ),
      StatusItem(
        title: 'Ayarlar',
        value: 'Yakında',
        color: _currentUser!.isAdmin ? const Color(0xFF8B5CF6) : const Color(0xFF0066FF),
        icon: _currentUser!.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
      ),
    ];

    return AnimatedBuilder(
      animation: _cardsController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getStatusGridColumns(context),
            crossAxisSpacing: _isMobile(context) ? 8 : 12,
            mainAxisSpacing: _isMobile(context) ? 8 : 12,
            childAspectRatio: _isMobile(context) ? 2.5 : _isTablet(context) ? 2.0 : 2.8,
          ),
          itemCount: statusItems.length,
          itemBuilder: (context, index) {
            final item = statusItems[index];
            final delay = index * 0.1;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (delay * 1000).round()),
              tween: Tween(begin: 0.0, end: _cardsController.value),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildStatusCard(item, theme, isDark),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusCard(StatusItem item, ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: _isMobile(context) ? 24 : 28,
            height: _isMobile(context) ? 24 : 28,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: _isMobile(context) ? 14 : 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 10 : 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(ThemeData theme, bool isDark) {
    // Aktif olmayan kullanıcılar için ödeme + yol haritası menüsü
    final List<MenuItem> menuItems;

    if (!_currentUser!.hasActivePackage) {
      menuItems = [
        MenuItem(
          icon: Icons.route_rounded,
          title: 'Yol Haritası',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoadmapScreen()),
            );
          },
        ),
        MenuItem(
          icon: Icons.payment_rounded,
          title: 'Ödeme Ekle',
          color: const Color(0xFFFFB800),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => OdemelerPage(),
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
            );
          },
        ),
      ];
    } else {
      // Aktif kullanıcılar için tüm menü
      menuItems = [
        MenuItem(
          icon: Icons.route_rounded,
          title: 'Yol Haritası',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RoadmapScreen()),
            );
          },
        ),
        MenuItem(
          icon: Icons.play_circle_rounded,
          title: 'Videolar',
          color: const Color(0xFFEF4444),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => TeachersPage(),
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
            );
          },
        ),
        MenuItem(
          icon: Icons.payment_rounded,
          title: 'Ödemeler',
          color: const Color(0xFFFFB800),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => OdemelerPage(),
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
            );
          },
        ),
        MenuItem(
          icon: Icons.folder_rounded,
          title: 'Dosyalar',
          color: const Color(0xFF10B981),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => FilesPage(),
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
            );
          },
        ),
        MenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Soru Sor',
          color: const Color(0xFFFF6B35),
          onTap: () {
            // Geçici olarak devre dışı
            context.showComingSoon('Soru Sor');
            // Aktif hale getirmek için:
            // _showAskTeacherDialog();
          },
        ),
        MenuItem(
          icon: Icons.quiz_rounded,
          title: 'Quizler',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.showComingSoon('Quizler'),
        ),
        MenuItem(
          icon: Icons.person_rounded,
          title: 'Profil',
          color: const Color(0xFF0891B2),
          onTap: () => context.showComingSoon('Profil'),
        ),
      ];
    }

    return AnimatedBuilder(
      animation: _cardsController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentUser!.hasActivePackage ? 'Menü' : 'Özellikler',
              style: TextStyle(
                fontSize: _isMobile(context) ? 20 : _isTablet(context) ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: _isMobile(context) ? 12 : 16),

            // Aktif olmayan kullanıcılar için uyarı mesajı
            if (!_currentUser!.hasActivePackage) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
                margin: EdgeInsets.only(bottom: _isMobile(context) ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB800).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFFFB800),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ödeme Bekleniyor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFB800),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yol haritasını inceleyebilirsiniz. Diğer özelliklere erişim için ödeme yapmanız gerekmektedir.',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _currentUser!.hasActivePackage
                    ? _getMenuGridColumns(context)
                    : 2, // Aktif değilse 2 kolon (yol haritası + ödeme)
                crossAxisSpacing: _isMobile(context) ? 12 : 16,
                mainAxisSpacing: _isMobile(context) ? 12 : 16,
                childAspectRatio: _currentUser!.hasActivePackage
                    ? (_isMobile(context) ? 1.0 : _isTablet(context) ? 1.1 : 1.2)
                    : (_isMobile(context) ? 1.0 : 1.2), // Aktif değilse kare benzeri
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final delay = index * 0.1;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800 + (delay * 1000).round()),
                  tween: Tween(begin: 0.0, end: _cardsController.value),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: _buildMenuCard(item, theme, isDark),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
  void _showAskTeacherDialog() {
    if (_currentUser?.ogretmenAdi == null) {
      context.showError('Henüz bir öğretmen atanmamış');
      return;
    }

    final TextEditingController questionController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: _isMobile(context) ? MediaQuery.of(context).size.width * 0.9 : 500,
                padding: EdgeInsets.all(_isMobile(context) ? 20 : 24),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Öğretmene Soru Sor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _currentUser!.ogretmenAdi!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Konu başlığı
                    Text(
                      'Konu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        hintText: 'Soru konusu (örn: Matematik - Türev)',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Soru
                    Text(
                      'Sorunuz',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Sorunuzu detaylı bir şekilde yazın...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () async {
                              if (subjectController.text.trim().isEmpty) {
                                context.showError('Lütfen konu başlığı girin');
                                return;
                              }
                              if (questionController.text.trim().isEmpty) {
                                context.showError('Lütfen sorunuzu yazın');
                                return;
                              }

                              setState(() => isLoading = true);

                              try {
                                await _sendQuestionToTeacher(
                                  subjectController.text.trim(),
                                  questionController.text.trim(),
                                );
                                Navigator.pop(context);
                                context.showSuccess('Sorunuz öğretmeninize iletildi!');
                              } catch (e) {
                                context.showError('Soru gönderilemedi: $e');
                              } finally {
                                setState(() => isLoading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Soruyu Gönder',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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
      },
    );
  }

  // Soruyu öğretmene gönder
  Future<void> _sendQuestionToTeacher(String subject, String question) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Oturum süresi dolmuş');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/ask-teacher'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'subject': subject,
        'question': question,
        'teacher_id': _currentUser?.ogretmenId, // Eğer öğretmen ID'si varsa
      }),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Sunucu hatası');
    }

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Soru gönderilemedi');
    }
  }

  Widget _buildMenuCard(MenuItem item, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      child: Container(
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
              blurRadius: _isMobile(context) ? 15 : 20,
              offset: Offset(0, _isMobile(context) ? 6 : 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isMobile(context) ? 16 : 20),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: _isMobile(context) ? 60 : 80,
                  height: _isMobile(context) ? 60 : 80,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: _isMobile(context) ? 40 : 50,
                      height: _isMobile(context) ? 40 : 50,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(_isMobile(context) ? 12 : 16),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: _isMobile(context) ? 20 : 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: _isMobile(context) ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: _isMobile(context) ? 24 : 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    // Debug için ekle
    print('Building theme toggle - currentThemeMode: ${widget.currentThemeMode}, isDark: $isDark');

    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabController.value,
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.mediumImpact();

              print('Current mode before change: ${widget.currentThemeMode}');

              final newMode = switch (widget.currentThemeMode) {
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
                ThemeMode.system => ThemeMode.light,
              };

              print('Calling onThemeChanged with: $newMode');
              widget.onThemeChanged(newMode);

              // Callback sonrası kontrol için
              Future.delayed(Duration(milliseconds: 100), () {
                print('After callback - currentThemeMode: ${widget.currentThemeMode}');
              });
            },
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            elevation: 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _getThemeIcon(),
                key: ValueKey(widget.currentThemeMode), // Bu değer değişmeli
                color: isDark ? Colors.white : Colors.black,
                size: _isMobile(context) ? 20 : 24,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getThemeIcon() {
    print('Getting theme icon for: ${widget.currentThemeMode}');
    return switch (widget.currentThemeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };
  }
  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeMode != widget.currentThemeMode) {
      setState(() {});
    }
  }
}

// Model classes
class StatusItem {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  StatusItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class MenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}