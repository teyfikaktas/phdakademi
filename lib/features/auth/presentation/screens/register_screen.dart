// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:phd_akademi/features/auth/presentation/screens/register_success_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final ThemeMode? currentThemeMode;

  const RegisterScreen({
    Key? key,
    this.onThemeChanged,
    this.currentThemeMode,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';
  String _selectedTeacher = '1';
  String _selectedExam = 'YDS';
  String _selectedCity = 'İstanbul';
  bool _joinKelibu = true;
  bool _joinSelfEnglish = true;
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _buttonController;

  // Öğretmen listesi
  final List<Map<String, String>> _teachers = [
    {'id': '1', 'name': 'Veysel Şenol'},
    {'id': '2', 'name': 'Ertuğrul Kırtay'},
    {'id': '3', 'name': 'Birol Dudu'},
  ];

  // Eğitim amacı listesi
  final List<String> _examTypes = [
    'YDS',
    'YDT',
    'YÖKDİL',
    'Genel İngilizce',
    'IELTS',
    'TOEFL',
  ];

  // Türkiye illeri listesi
  final List<String> _cities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
    'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
    'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis',
    'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
    'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
    'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir',
    'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu',
    'Kayseri', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kilis',
    'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Mardin',
    'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu',
    'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop',
    'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon',
    'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
    'Türkiye\'de yaşamıyorum'
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startAnimations() {
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _formController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
  void _navigateToSuccessPage(Map<String, dynamic> data) {
    // Öğretmen adını bul
    String? teacherName;
    final teacher = _teachers.firstWhere(
          (t) => t['id'] == _selectedTeacher,
      orElse: () => {'name': 'null'},
    );
    teacherName = teacher['name'];

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => RegisterSuccessScreen(
          currentThemeMode: widget.currentThemeMode,
          onThemeChanged: widget.onThemeChanged,
          userName: data['data']?['name'] ?? _nameController.text.split(' ').first,
          teacherName: teacherName,
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
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Apps modal'ını göster
    _showAppsModal();
  }
  void _showAppsModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AppsSelectionModal(
          currentThemeMode: widget.currentThemeMode,
          initialKelibu: _joinKelibu,
          initialSelfEnglish: _joinSelfEnglish,
          onConfirm: (joinKelibu, joinSelfEnglish) {
            setState(() {
              _joinKelibu = joinKelibu;
              _joinSelfEnglish = joinSelfEnglish;
            });
            _performRegistration();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _performRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    HapticFeedback.mediumImpact();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'adsoyad': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'telefon': _phoneController.text.trim(),
          'sifre': _passwordController.text,
          'ogretmen_id': _selectedTeacher,
          'exam': _selectedExam,
          'join_kelibu': _joinKelibu,
          'join_selfenglish': _joinSelfEnglish,
          'adres': _selectedCity,
        }),
      ).timeout(Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        HapticFeedback.lightImpact();
        _navigateToSuccessPage(data);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = data['message'] ?? 'Kayıt başarısız';
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                begin: const Offset(-0.1, 0.0),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBackButton(isDark),
                      SizedBox(height: _isMobile(context) ? 16 : 24),
                      _buildLogo(isDark),
                      SizedBox(height: _isMobile(context) ? 32 : 40),
                      _buildWelcomeTexts(theme),
                      SizedBox(height: _isMobile(context) ? 32 : 40),
                      _buildForm(theme, isDark),
                      SizedBox(height: _isMobile(context) ? 24 : 32),
                      _buildRegisterButton(theme, isDark),
                      SizedBox(height: _isMobile(context) ? 24 : 32),
                      _buildLoginInfo(theme, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppCheckbox(
      ThemeData theme,
      bool isDark,
      String appName,
      String description,
      bool value,
      ValueChanged<bool?> onChanged,
      Color accentColor,
      ) {
    String logoPath = appName == 'Kelibu' ? 'assets/kelibu.png' : 'assets/selfenglish.png';
    IconData fallbackIcon = appName == 'Kelibu' ? Icons.translate_rounded : Icons.school_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? accentColor.withOpacity(0.3)
              : (isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: accentColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                logoPath,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      fallbackIcon,
                      color: accentColor,
                      size: 18,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value
                        ? accentColor
                        : theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBackButton(bool isDark) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoController.value,
          child: Opacity(
            opacity: _logoController.value,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _navigateToLogin();
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.black54,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * _logoController.value),
          child: Opacity(
            opacity: _logoController.value,
            child: Center(
              child: Container(
                width: _isMobile(context) ? 80 : 100,
                height: _isMobile(context) ? 80 : 100,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/qrcode.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF3B82F6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'PhD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isMobile(context) ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeTexts(ThemeData theme) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _logoController.value)),
          child: Opacity(
            opacity: _logoController.value,
            child: Column(
              children: [
                Text(
                  'Hesap Oluştur',
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 26 : 30,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'PhD Akademi ailesine katılın!',
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 22 : 26,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bilgilerinizi girdikten sonra öğretmeniniz sizinle iletişime geçecektir.',
                  style: TextStyle(
                    fontSize: _isMobile(context) ? 14 : 15,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }Widget _buildForm(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _formController.value)),
          child: Opacity(
            opacity: _formController.value,
            child: Column(
              children: [
                // Ad Soyad ve Email - Yan yana
                Row(
                  children: [
                    Expanded(
                      child: _buildNameField(theme, isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEmailField(theme, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Öğretmen seçimi
                _buildTeacherDropdown(theme, isDark),
                const SizedBox(height: 20),

                // Telefon ve Şifre - Yan yana
                Row(
                  children: [
                    Expanded(
                      child: _buildPhoneField(theme, isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPasswordField(theme, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Eğitim Amacı ve Şehir - Yan yana
                Row(
                  children: [
                    Expanded(
                      child: _buildExamDropdown(theme, isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCityDropdown(theme, isDark),
                    ),
                  ],
                ),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildErrorMessage(theme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: _nameController,
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Ad Soyad',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF10B981),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ad soyad gerekli';
          }
          if (value.trim().split(' ').length < 2) {
            return 'Ad ve soyadı girin';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'E-posta',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.email_rounded,
              color: Color(0xFF3B82F6),
              size: 18,
            ),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'E-posta gerekli';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Geçerli e-posta girin';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTeacherDropdown(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTeacher,
        decoration: InputDecoration(
          labelText: 'Öğretmen Seçin',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF8B5CF6),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
        ),
        items: _teachers.map((teacher) {
          return DropdownMenuItem<String>(
            value: teacher['id'],
            child: Text(teacher['name']!),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedTeacher = value!;
          });
        },
      ),
    );
  }

  Widget _buildPhoneField(ThemeData theme, bool isDark) {
    return Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
    blurRadius: 15,
    offset: const Offset(0, 8),
    ),
    ],
    ),
    child: TextFormField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    style: TextStyle(
    fontSize: 15,
    color: theme.colorScheme.onSurface,
    ),
    decoration: InputDecoration(
    labelText: 'Telefon',
    labelStyle: TextStyle(
    color: theme.colorScheme.onSurface.withOpacity(0.6),
    fontSize: 13,
    ),
    prefixIcon: Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
    color: const Color(0xFFF59E0B).withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
    Icons.phone_rounded,
    color: Color(0xFFF59E0B),
    size: 18,
    ),
    ),
    filled: true,
    fillColor: isDark
    ? Colors.white.withOpacity(0.05)
        : Colors.white,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
    color: isDark
    ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05),
    ),
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(
    color: Color(0xFFF59E0B),
    width: 2,
    ),
    ),
    errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(
    color: Color(0xFFEF4444),width: 2,
    ),
    ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Telefon numarası gerekli';
        }
        if (!RegExp(r'^05[0-9]{9}$').hasMatch(value.replaceAll(' ', ''))) {
          return '05XXXXXXXXX formatında girin';
        }
        return null;
      },
    ),
    );
  }

  Widget _buildPasswordField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: TextStyle(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Şifre',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Şifre gerekli';
          }
          if (value.length < 6) {
            return 'En az 6 karakter';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildExamDropdown(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedExam,
        decoration: InputDecoration(
          labelText: 'Eğitim Amacı',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF06B6D4),
              size: 18,
            ),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF06B6D4),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 15,
        ),
        items: _examTypes.map((exam) {
          return DropdownMenuItem<String>(
            value: exam,
            child: Text(exam),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedExam = value!;
          });
        },
      ),
    );
  }

  Widget _buildCityDropdown(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        decoration: InputDecoration(
          labelText: 'Şehir',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF84CC16).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: Color(0xFF84CC16),
              size: 18,
            ),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF84CC16),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 15,
        ),
        items: _cities.map((city) {
          return DropdownMenuItem<String>(
            value: city,
            child: Text(city),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCity = value!;
          });
        },
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _buttonController.value),
          child: Opacity(
            opacity: _buttonController.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: _isMobile(context) ? 18 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginInfo(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _buttonController.value)),
          child: Opacity(
            opacity: _buttonController.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withOpacity(0.15)
                    : const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.login_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hesabın var mı? ',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _navigateToLogin();
                    },
                    child: Text(
                      'Giriş Yap',
                      style: TextStyle(
                        color: const Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
}
class _AppsSelectionModal extends StatefulWidget {
  final ThemeMode? currentThemeMode;
  final bool initialKelibu;
  final bool initialSelfEnglish;
  final Function(bool, bool) onConfirm;
  final VoidCallback onCancel;

  const _AppsSelectionModal({
    required this.currentThemeMode,
    required this.initialKelibu,
    required this.initialSelfEnglish,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  _AppsSelectionModalState createState() => _AppsSelectionModalState();
}

class _AppsSelectionModalState extends State<_AppsSelectionModal>
    with TickerProviderStateMixin {
  late bool _joinKelibu;
  late bool _joinSelfEnglish;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _joinKelibu = widget.initialKelibu;
    _joinSelfEnglish = widget.initialSelfEnglish;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  String _getSelectionMessage() {
    if (_joinKelibu && _joinSelfEnglish) {
      return 'Her iki uygulamaya otomatik üyeliğiniz oluşturulacaktır';
    } else if (_joinKelibu) {
      return 'Kelibu uygulamasına otomatik üyeliğiniz oluşturulacaktır';
    } else if (_joinSelfEnglish) {
      return 'SelfEnglish uygulamasına otomatik üyeliğiniz oluşturulacaktır';
    } else {
      return 'Hiçbir uygulamaya üye olmayacaksınız';
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
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
                      // Header
// Header kısmını bununla değiştir:
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.apps_rounded,
                              color: const Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diğer Uygulamalarımız',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _getSelectionMessage(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Apps
                      _buildAppOption(
                        theme,
                        isDark,
                        'Kelibu',
                        'Kelime haznenizi güçlendirin - 3000+ kelime ile',
                        _joinKelibu,
                            (value) => setState(() => _joinKelibu = value!),
                        const Color(0xFF8B5CF6),
                        'assets/kelibu.png',
                        Icons.translate_rounded,
                      ),

                      const SizedBox(height: 16),

                      _buildAppOption(
                        theme,
                        isDark,
                        'SelfEnglish',
                        'İngilizce gramer konularını kendi hızınızda öğrenin',
                        _joinSelfEnglish,
                            (value) => setState(() => _joinSelfEnglish = value!),
                        const Color(0xFF06B6D4),
                        'assets/selfenglish.png',
                        Icons.school_rounded,
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: widget.onCancel,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Text(
                                'İptal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop();
                                widget.onConfirm(_joinKelibu, _joinSelfEnglish);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  fontSize: 16,
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppOption(
      ThemeData theme,
      bool isDark,
      String appName,
      String description,
      bool value,
      ValueChanged<bool?> onChanged,
      Color accentColor,
      String logoPath,
      IconData fallbackIcon,
      ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value
              ? accentColor.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? accentColor.withOpacity(0.4)
                : theme.colorScheme.onSurface.withOpacity(0.1),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: accentColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  logoPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      fallbackIcon,
                      color: accentColor,
                      size: 20,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: value
                          ? accentColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}