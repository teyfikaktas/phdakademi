import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/snackbar_utils.dart';

class PaymentDetailPage extends StatefulWidget {
  final Map<String, dynamic> odeme;
  final bool isTeacher;

  const PaymentDetailPage({
    Key? key,
    required this.odeme,
    required this.isTeacher,
  }) : super(key: key);

  @override
  _PaymentDetailPageState createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  bool _isLoading = false;
  late Map<String, dynamic> currentOdeme;

  @override
  void initState() {
    super.initState();
    currentOdeme = Map<String, dynamic>.from(widget.odeme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ödeme Detayı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isTeacher && currentOdeme['odeme_durum'] == 0)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'approve') {
                  _approvePayment();
                } else if (value == 'reject') {
                  _rejectPayment();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Onayla'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Reddet'),
                    ],
                  ),
                ),
              ],
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(theme, isDark),
          SizedBox(height: 16),
          _buildInfoCard(theme, isDark),
          SizedBox(height: 16),
          if (currentOdeme['MonthComment'] != null &&
              currentOdeme['MonthComment'].toString().isNotEmpty)
            _buildCommentCard(theme, isDark),
          if (widget.isTeacher && currentOdeme['kullanici'] != null) ...[
            SizedBox(height: 16),
            _buildUserInfoCard(theme, isDark),
          ],
          SizedBox(height: 24),
          if (widget.isTeacher && currentOdeme['odeme_durum'] == 0)
            _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final int odeme_durum = currentOdeme['odeme_durum'] ?? 0;
    final bool isApproved = odeme_durum == 1;
    final bool isPending = odeme_durum == 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isApproved) {
      statusColor = Colors.green;
      statusText = 'Onaylandı';
      statusIcon = Icons.check_circle;
    } else if (isPending) {
      statusColor = Colors.orange;
      statusText = 'Bekliyor';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.red;
      statusText = 'Reddedildi';
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₺${_formatMoney(currentOdeme['tutar'])}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPending && !widget.isTeacher) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ödemeniz öğretmeniniz tarafından onay bekleniyor',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              'Açıklama',
              currentOdeme['aciklama'] ?? 'Açıklama yok',
              Icons.description,
              theme,
              isDark,
            ),
            SizedBox(height: 12),
            _buildInfoRow(
              'Oluşturulma Tarihi',
              _formatDetailDate(currentOdeme['created_at']),
              Icons.calendar_today,
              theme,
              isDark,
            ),
            if (currentOdeme['updated_at'] != currentOdeme['created_at']) ...[
              SizedBox(height: 12),
              _buildInfoRow(
                'Son Güncelleme',
                _formatDetailDate(currentOdeme['updated_at']),
                Icons.update,
                theme,
                isDark,
              ),
            ],
            SizedBox(height: 12),
            _buildInfoRow(
              'Ödeme ID',
              '#${currentOdeme['id']}',
              Icons.tag,
              theme,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Yorum',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              currentOdeme['MonthComment'],
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme, bool isDark) {
    final user = currentOdeme['kullanici'];

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Öğrenci Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Color(0xFF1E40AF), Color(0xFF3B82F6)]
                          : [Color(0xFF0066FF), Color(0xFF00D4FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user['adsoyad'] ?? 'Ö').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['adsoyad'] ?? 'İsimsiz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (user['telefon'] != null) ...[
                        SizedBox(height: 4),
                        Text(
                          user['telefon'],
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      IconData icon,
      ThemeData theme,
      bool isDark,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rejectPayment(),
            icon: Icon(Icons.close, size: 20),
            label: Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _approvePayment(),
            icon: Icon(Icons.check, size: 20),
            label: Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approvePayment() async {
    await _updatePaymentStatus(1, 1);
  }

  Future<void> _rejectPayment() async {
    await _updatePaymentStatus(0, 0);
  }

  Future<void> _updatePaymentStatus(int odeme_durum, int odemeonayi) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        context.showError('Oturum süresi dolmuş');
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/student/odemeler/${currentOdeme['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tutar': currentOdeme['tutar'],
          'aciklama': currentOdeme['aciklama'],
          'odeme_durum': odeme_durum,
          'odemeonayi': odemeonayi,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            currentOdeme['odeme_durum'] = odeme_durum;
            currentOdeme['odemeonayi'] = odemeonayi;
          });

          final statusText = odeme_durum == 1 ? 'onaylandı' : 'reddedildi';
          context.showSuccess('Ödeme $statusText');
        } else {
          context.showError(data['message'] ?? 'Bir hata oluştu');
        }
      } else {
        context.showError('Sunucu hatası');
      }
    } catch (e) {
      context.showError('Bağlantı hatası');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return '0';
    double value = double.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0);
  }

  String _formatDetailDate(String? dateString) {
    if (dateString == null) return 'Tarih yok';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Tarih yok';
    }
  }
}