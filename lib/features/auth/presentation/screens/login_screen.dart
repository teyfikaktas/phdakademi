// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phd_akademi/features/dashboard/dashboard_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/user_entity.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // UserEntity oluştur
        final userEntity = UserEntity.fromJson(data['data']['user']);

        // Token ve kullanıcı bilgilerini kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['data']['token']);

        // UserEntity'yi JSON string olarak kaydet
        await prefs.setString('user_data', json.encode(data['data']['user']));

        // Hızlı erişim için temel bilgileri de kaydet
        await prefs.setString('user_name', userEntity.name);
        await prefs.setString('user_email', userEntity.email);
        await prefs.setInt('user_id', userEntity.id);
        await prefs.setBool('is_admin', userEntity.isAdmin);
        await prefs.setBool('is_active', userEntity.isActive);

        // Mevcut tema modunu al (yoksa light kullan)
        final String? savedThemeMode = prefs.getString('theme_mode');
        ThemeMode currentTheme = ThemeMode.light; // varsayılan

        if (savedThemeMode != null) {
          switch (savedThemeMode) {
            case 'dark':
              currentTheme = ThemeMode.dark;
              break;
            case 'system':
              currentTheme = ThemeMode.system;
              break;
            default:
              currentTheme = ThemeMode.light;
              break;
          }
        }

        // Dashboard'a git ve gerekli parametreleri geçir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userEntity: userEntity,
              currentThemeMode: currentTheme, // ✅ Eksik olan parametre
              onThemeChanged: (ThemeMode newTheme) {
                // Tema değiştiğinde SharedPreferences'a kaydet
                _saveThemeMode(newTheme);
              },
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Giriş başarısız';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Tema modunu SharedPreferences'a kaydet
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;

    switch (themeMode) {
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
      default:
        themeModeString = 'light';
        break;
    }

    await prefs.setString('theme_mode', themeModeString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60),

                // Logo
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'PhD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40),

                Text(
                  'Hoş Geldiniz!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                Text(
                  'Hesabınıza giriş yapın',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta adresi gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock, color: Colors.blue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 3) {
                      return 'Şifre en az 3 karakter olmalı';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_errorMessage.isNotEmpty) SizedBox(height: 16),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Test bilgileri (sadece development için)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🧪 Test için:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Gerçek kullanıcı bilgilerinizi girin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}