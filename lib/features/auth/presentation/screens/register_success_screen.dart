// lib/features/auth/presentation/screens/register_success_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import '../../../dashboard/dashboard_screen.dart';

class RegisterSuccessScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final ThemeMode? currentThemeMode;
  final String? userName;
  final String? teacherName;

  const RegisterSuccessScreen({
    Key? key,
    this.onThemeChanged,
    this.currentThemeMode,
    this.userName,
    this.teacherName,
  }) : super(key: key);

  @override
  _RegisterSuccessScreenState createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _buttonController;
  late AnimationController _floatingController;
  late AnimationController _countdownController;

  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _startCountdown();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _startAnimations() {
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _buttonController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      _floatingController.repeat(reverse: true);
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _countdownController.forward().then((_) {
          if (mounted) {
            setState(() {
              _countdown--;
            });
            _countdownController.reset();

            if (_countdown > 0) {
              _startCountdown();
            } else {
              _navigateToDashboard();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    _floatingController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  // Responsive helpers
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;

  double _getHorizontalPadding(BuildContext context) {
    if (_isMobile(context)) return 24.0;
    if (_isTablet(context)) return 48.0;
    return 64.0;
  }

  double _getMaxWidth(BuildContext context) {
    if (_isMobile(context)) return double.infinity;
    if (_isTablet(context)) return 600;
    return 550;
  }

  void _navigateToDashboard() {
    // Dashboard sayfasına yönlendirme - dashboard sayfanızı buraya ekleyin
    // Örnek: DashboardScreen() yerine kendi dashboard sayfanızı kullanın
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => LoginScreen( // DashboardScreen ile değiştirin
          currentThemeMode: widget.currentThemeMode,
          onThemeChanged: widget.onThemeChanged,
        ),
        transitionDuration: const Duration(milliseconds: 1000),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => LoginScreen(
          currentThemeMode: widget.currentThemeMode,
          onThemeChanged: widget.onThemeChanged,
        ),
        transitionDuration: const Duration(milliseconds: 1000),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ]
                : [
              const Color(0xFFF8FAFC),
              const Color(0xFFFFFFFF),
              const Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _getMaxWidth(context)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: _getHorizontalPadding(context),
                  vertical: _isMobile(context) ? 24 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSuccessIcon(isDark),
                    SizedBox(height: _isMobile(context) ? 24 : 32),
                    _buildSuccessTexts(theme),
                    SizedBox(height: _isMobile(context) ? 24 : 32),
                    _buildInfoCards(theme, isDark),
                    SizedBox(height: _isMobile(context) ? 16 : 20),
                    _buildCountdownInfo(theme, isDark),
                    SizedBox(height: _isMobile(context) ? 24 : 32),
                    _buildActionButtons(theme, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(bool isDark) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -8 * _floatingController.value),
              child: Transform.scale(
                scale: 0.4 + (0.6 * _logoController.value),
                child: Opacity(
                  opacity: _logoController.value,
                  child: Center(
                    child: Container(
                      width: _isMobile(context) ? 80 : 100,
                      height: _isMobile(context) ? 80 : 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF34D399),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: _isMobile(context) ? 40 : 50,
                        color: Colors.white,
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

  Widget _buildSuccessTexts(ThemeData theme) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _contentController.value)),
          child: Opacity(
            opacity: _contentController.value,
            child: Column(
              children: [
                Text(
                  'Kayıt Başarılı! 🎉',
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (widget.userName != null) ...[
                  Text(
                    'Hoş geldin ${widget.userName}!',
                    style: TextStyle(
                      fontSize: _isMobile(context) ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Kayıt olduğunuz için teşekkürler! Öğretmeniniz en kısa zamanda sizinle iletişime geçecektir.',
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 14 : 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCards(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _contentController.value)),
          child: Opacity(
            opacity: _contentController.value,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 300),
                child: _buildInfoCard(
                  isDark,
                  Icons.school_rounded,
                  'Öğretmen Onayı',
                  widget.teacherName != null
                      ? '${widget.teacherName} onayı bekliyor'
                      : 'Öğretmen onayı bekleniyor',
                  const Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(bool isDark, IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.15)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownInfo(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _countdownController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * _countdownController.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'saniye sonra giriş sayfasına yönlendirileceksiniz, giriş yapıp adımları izleyebilirsiniz.',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _buttonController.value),
          child: Opacity(
            opacity: _buttonController.value,
            child: Column(
              children: [
                // Ana Giriş Butonu
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _navigateToLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: _isMobile(context) ? 16 : 18,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Şimdi Giriş Yap',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // İletişim Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Herhangi bir sorunuz varsa öğretmeninizle iletişime geçebilirsiniz',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
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
}