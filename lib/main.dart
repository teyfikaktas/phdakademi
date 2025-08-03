// main.dart - Basit ve temiz theme setup
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama başlarken izinleri iste
  await _requestPermissions();

  runApp(const MyApp());
}

// İzin isteme fonksiyonu
Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    try {
      // Android sürümüne göre farklı izinler iste
      List<Permission> permissions = [
        Permission.storage,
      ];

      // Android 11+ için ek izinler
      if (await Permission.manageExternalStorage.isDenied) {
        permissions.add(Permission.manageExternalStorage);
      }

      // Android 13+ için medya izinleri
      if (await Permission.photos.isDenied) {
        permissions.add(Permission.photos);
      }
      if (await Permission.videos.isDenied) {
        permissions.add(Permission.videos);
      }

      // İzinleri toplu olarak iste
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // İzin durumlarını logla
      statuses.forEach((permission, status) {
        print('${permission.toString()} izni: ${status.toString()}');
      });

      // Kritik izinler reddedildiyse kullanıcıyı bilgilendir
      if (statuses[Permission.storage] == PermissionStatus.permanentlyDenied ||
          statuses[Permission.manageExternalStorage] == PermissionStatus.permanentlyDenied) {
        print('Dosya erişim izni kalıcı olarak reddedildi. Ayarlardan açılması gerekiyor.');
      }

    } catch (e) {
      print('İzin isteme hatası: $e');
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
        cardTheme: CardTheme(
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
        cardTheme: CardTheme(
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