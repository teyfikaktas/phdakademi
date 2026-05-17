// main.dart - Android 13+ uyumlu izin yönetimi ile
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama başlarken izinleri iste
  await _requestPermissions();

  runApp(const MyApp());
}

// Android 13+ uyumlu izin isteme fonksiyonu
Future<void> _requestPermissions() async {
  if (kIsWeb) {
    return; // Web'de hiçbir şey yapma
  }

  if (Platform.isAndroid) {
    try {
      // Android sürümünü kontrol et
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      print('Android SDK Sürümü: $sdkVersion');

      List<Permission> permissions = [];

      if (sdkVersion >= 33) {
        // Android 13+ (API 33+) için yeni izinler
        permissions.addAll([
          Permission.photos,        // READ_MEDIA_IMAGES
          Permission.videos,        // READ_MEDIA_VIDEO
          Permission.camera,        // Kamera (opsiyonel)
        ]);

        print('Android 13+ izinleri eklendi: photos, videos, camera');
      } else if (sdkVersion >= 30) {
        // Android 11-12 (API 30-32) için
        permissions.addAll([
          Permission.storage,              // READ_EXTERNAL_STORAGE
          Permission.manageExternalStorage, // Yönetim izni
          Permission.camera,
        ]);

        print('Android 11-12 izinleri eklendi: storage, manageExternalStorage, camera');
      } else {
        // Android 10 ve altı (API 29 ve altı) için
        permissions.addAll([
          Permission.storage,
          Permission.camera,
        ]);

        print('Android 10 ve altı izinleri eklendi: storage, camera');
      }

      // İzinleri kontrol et ve iste
      Map<Permission, PermissionStatus> statuses = {};

      for (Permission permission in permissions) {
        PermissionStatus status = await permission.status;

        if (status.isDenied || status.isRestricted) {
          print('${permission.toString()} izni reddedilmiş, isteniyor...');
          PermissionStatus newStatus = await permission.request();
          statuses[permission] = newStatus;
        } else {
          statuses[permission] = status;
        }
      }

      // İzin durumlarını logla
      print('\n=== İZİN DURUMLARI ===');
      statuses.forEach((permission, status) {
        String permissionName = _getPermissionName(permission);
        String statusName = _getStatusName(status);
        print('$permissionName: $statusName');
      });

      // Kritik izinler için uyarı
      await _checkCriticalPermissions(statuses, sdkVersion);

    } catch (e) {
      print('İzin isteme hatası: $e');
    }
  }
}

// İzin adlarını daha okunabilir hale getir
String _getPermissionName(Permission permission) {
  switch (permission) {
    case Permission.photos:
      return 'Fotoğraflar';
    case Permission.videos:
      return 'Videolar';
    case Permission.camera:
      return 'Kamera';
    case Permission.storage:
      return 'Depolama';
    case Permission.manageExternalStorage:
      return 'Harici Depolama Yönetimi';
    default:
      return permission.toString();
  }
}

// İzin durumlarını daha okunabilir hale getir
String _getStatusName(PermissionStatus status) {
  switch (status) {
    case PermissionStatus.granted:
      return '✅ Verildi';
    case PermissionStatus.denied:
      return '❌ Reddedildi';
    case PermissionStatus.restricted:
      return '🚫 Kısıtlı';
    case PermissionStatus.limited:
      return '⚠️ Sınırlı';
    case PermissionStatus.permanentlyDenied:
      return '🔒 Kalıcı Reddedildi';
    case PermissionStatus.provisional:
      return '⏱️ Geçici';
    default:
      return status.toString();
  }
}

// Kritik izinleri kontrol et
Future<void> _checkCriticalPermissions(Map<Permission, PermissionStatus> statuses, int sdkVersion) async {
  List<String> deniedPermissions = [];

  statuses.forEach((permission, status) {
    if (status.isPermanentlyDenied) {
      deniedPermissions.add(_getPermissionName(permission));
    }
  });

  if (deniedPermissions.isNotEmpty) {
    print('\n⚠️  UYARI: Şu izinler kalıcı olarak reddedildi:');
    for (String permission in deniedPermissions) {
      print('   • $permission');
    }
    print('   Bu izinler olmadan bazı özellikler çalışmayabilir.');
    print('   Ayarlar > Uygulamalar > PhD Akademi > İzinler\'den açabilirsiniz.');
  }

  // Android 13+ özel kontrolleri
  if (sdkVersion >= 33) {
    bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
    bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

    if (!photosGranted || !videosGranted) {
      print('\n📱 Android 13+ Bilgi:');
      if (!photosGranted) print('   • Profil fotoğrafı seçimi için Fotoğraflar izni gerekli');
      if (!videosGranted) print('   • Video ödevleri için Video izni gerekli');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhD Akademi',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // Light Theme - Modern & Clean
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFF8FAFC),
          onSurface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Dark Theme - Premium & Sleek
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF0A0A0A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
      home: DashboardScreen(
        onThemeChanged: changeTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}