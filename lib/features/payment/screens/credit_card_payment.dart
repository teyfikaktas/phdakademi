import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phd_akademi/features/payment/screens/payment.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/snackbar_utils.dart';

class SubscriptionPackagesPage extends StatefulWidget {
  @override
  _SubscriptionPackagesPageState createState() => _SubscriptionPackagesPageState();
}

class _SubscriptionPackagesPageState extends State<SubscriptionPackagesPage> {
  int? _selectedPackageIndex;
  bool _isLoading = false;

  final List<SubscriptionPackage> _packages = [
    SubscriptionPackage(
      id: 'phd_monthly',
      title: 'PhD Akademi',
      subtitle: 'Aylık Abonelik',
      price: 4000,
      originalPrice: null,
      duration: '1 Ay',
      features: [
        'Tüm video derslere erişim',
        'Kişisel ödev planı',
        'Eğitmen takibi',
      ],
      badge: null,
      isRecurring: true,
      color: Color(0xFF0066FF),
      icon: null,
    ),
    SubscriptionPackage(
      id: 'kelibu_monthly',
      title: 'Kelibu Pro',
      subtitle: 'Aylık Abonelik',
      price: 250,
      originalPrice: null,
      duration: '1 Ay',
      features: [
        'Tüm kelime setlerine erişim',
      ],
      badge: null,
      isRecurring: true,
      color: Color(0xFF10B981),
      icon: 'assets/kelibu.png',
    ),
    SubscriptionPackage(
      id: 'kelibu_6month',
      title: 'Kelibu Pro',
      subtitle: '6 Aylık Abonelik',
      price: 1400,
      originalPrice: 1500,
      duration: '6 Ay',
      features: [
        'Tüm kelime setlerine erişim',
      ],
      badge: '%7 İNDİRİM',
      isRecurring: false,
      color: Color(0xFFF59E0B),
      icon: 'assets/kelibu.png',
    ),
    SubscriptionPackage(
      id: 'kelibu_yearly',
      title: 'Kelibu Pro',
      subtitle: 'Yıllık Abonelik',
      price: 2100,
      originalPrice: 3000,
      duration: '12 Ay',
      features: [
        'Tüm kelime setlerine erişim',
      ],
      badge: 'EN AVANTAJLI',
      isRecurring: false,
      color: Color(0xFF8B5CF6),
      icon: 'assets/kelibu.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Abonelik Satın Al',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme, isDark),
                      SizedBox(height: 24),

                      // PhD Akademi Bölümü
                      Text(
                        'PhD Akademi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildPackageCard(_packages[0], 0, theme, isDark),

                      SizedBox(height: 24),

                      // Kelibu Bölümü
                      Text(
                        'Kelibu Pro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildPackageCard(_packages[1], 1, theme, isDark),
                      SizedBox(height: 12),
                      _buildPackageCard(_packages[2], 2, theme, isDark),
                      SizedBox(height: 12),
                      _buildPackageCard(_packages[3], 3, theme, isDark),

                      SizedBox(height: 16),
                      _buildInfoNote(isDark),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedPackageIndex != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _buildPurchaseButton(theme),
            ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1E40AF), Color(0xFF3B82F6)]
              : [Color(0xFF0066FF), Color(0xFF00D4FF)],
        ),
        borderRadius: BorderRadius.circular(16),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Paketler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Size uygun paketi seçin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
      SubscriptionPackage package,
      int index,
      ThemeData theme,
      bool isDark,
      ) {
    final isSelected = _selectedPackageIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackageIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? package.color
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: package.color.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: package.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: package.icon != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            package.icon!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Icon(
                          Icons.school,
                          color: package.color,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              package.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: package.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<int>(
                        value: index,
                        groupValue: _selectedPackageIndex,
                        onChanged: (value) {
                          setState(() {
                            _selectedPackageIndex = value;
                          });
                        },
                        activeColor: package.color,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${package.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: package.color,
                        ),
                      ),
                      if (package.originalPrice != null) ...[
                        SizedBox(width: 8),
                        Text(
                          '₺${package.originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          package.duration,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (package.isRecurring) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.refresh, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Her ay yenilenebilir',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: package.features.map((feature) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: package.color),
                          SizedBox(width: 4),
                          Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (package.badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: package.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    package.badge!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ödeme Bilgisi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Satın alma işleminiz kaydedildikten sonra eğitmeniniz tarafından onaylanacaktır.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(ThemeData theme) {
    final selectedPackage = _packages[_selectedPackageIndex!];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPackage.title,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    Text(
                      '₺${selectedPackage.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: selectedPackage.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _purchasePackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedPackage.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Satın Al',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Future<void> _purchasePackage() async {
    if (_selectedPackageIndex == null) return;

    final package = _packages[_selectedPackageIndex!];

    final paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardPaymentPage(
          packageTitle: package.title,
          amount: package.price,
          packageColor: package.color,
        ),
      ),
    );

    if (paymentResult != true) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/odemeler'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tutar': package.price,
          'aciklama': '${package.title} - ${package.subtitle}',
          'comment': 'Paket: ${package.id}, Süre: ${package.duration}',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          context.showSuccess('Ödeme başarılı! Aboneliğiniz aktif edildi.');
          Navigator.pop(context, true);
        } else {
          context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        context.showError(data['message'] ?? 'İşlem başarısız');
      } else {
        context.showError('Sunucu hatası');
      }
    } catch (e) {
      print('Subscription Purchase Error: $e');
      context.showError('Bağlantı hatası');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class SubscriptionPackage {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final double? originalPrice;
  final String duration;
  final List<String> features;
  final String? badge;
  final bool isRecurring;
  final Color color;
  final String? icon;

  SubscriptionPackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    required this.duration,
    required this.features,
    this.badge,
    required this.isRecurring,
    required this.color,
    this.icon,
  });
}