import 'package:flutter/material.dart';
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

class _OdemelerPageState extends State<OdemelerPage> {
  List<dynamic> odemeler = [];
  Map<String, dynamic>? odemeSummary;
  bool _isLoading = true;
  bool _isTeacher = false;
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchOdemeler();
    _fetchOdemeSummary();
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
        Uri.parse('${ApiConstants.baseUrl}/odemeler/summary/stats'),
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
      appBar: AppBar(
        title: Text(
          'Ödemeler',
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
          if (!_isTeacher)
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () => _navigateToAddPayment(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Stack(
          children: [
            _buildBody(theme, isDark),
            if (_isLoading && odemeler.isEmpty) _buildLoadingOverlay(),
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

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (odemeler.isEmpty && !_isLoading) {
      return _buildEmptyState(theme, isDark);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (odemeSummary != null)
          SliverToBoxAdapter(
            child: _buildSummaryCard(theme, isDark),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == odemeler.length && currentPage < totalPages) {
                _loadMoreData();
                return _buildLoadingItem();
              }
              if (index >= odemeler.length) return null;

              final odeme = odemeler[index];
              return _buildOdemeCard(odeme, theme, isDark);
            },
            childCount: odemeler.length + (currentPage < totalPages ? 1 : 0),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _isTeacher
                ? 'Henüz ödeme kaydı bulunmuyor'
                : 'Henüz ödeme eklememişsiniz',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          if (!_isTeacher)
            ElevatedButton.icon(
              onPressed: () => _navigateToAddPayment(),
              icon: Icon(Icons.add),
              label: Text('Ödeme Ekle'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTeacher ? 'Öğretmen Özeti' : 'Ödeme Özeti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isTeacher ? 'Tüm öğrenciler' : 'Kişisel durum',
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
          SizedBox(height: 20),
          if (_isTeacher) ..._buildTeacherSummary() else ..._buildStudentSummary(),
        ],
      ),
    );
  }

  List<Widget> _buildTeacherSummary() {
    return [
      _buildSummaryRow(
        'Toplam Gelir',
        '₺${_formatMoney(odemeSummary!['toplam_odeme'])}',
        Icons.trending_up,
      ),
      SizedBox(height: 12),
      _buildSummaryRow(
        'Bekleyen Ödemeler',
        '₺${_formatMoney(odemeSummary!['bekleyen_odeme'])}',
        Icons.schedule,
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Toplam Öğrenci',
              '${odemeSummary!['toplam_ogrenci']}',
              Icons.people,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildSummaryItem(
              'Aktif Öğrenci',
              '${odemeSummary!['aktif_ogrenci']}',
              Icons.person_outline,
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
        Icons.check_circle,
      ),
      SizedBox(height: 12),
      _buildSummaryRow(
        'Bekleyen Ödemeler',
        '₺${_formatMoney(odemeSummary!['bekleyen_odeme'])}',
        Icons.schedule,
      ),
      if (odemeSummary!['sonraki_odeme_tarihi'] != null) ...[
        SizedBox(height: 12),
        _buildSummaryRow(
          'Sonraki Ödeme',
          _formatDate(odemeSummary!['sonraki_odeme_tarihi']),
          Icons.calendar_today,
        ),
      ],
    ];
  }

  Widget _buildSummaryRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdemeCard(dynamic odeme, ThemeData theme, bool isDark) {
    // Güvenli type casting
    final dynamic rawOdemeDurum = odeme['odeme_durum'];
    final int odeme_durum = rawOdemeDurum is int
        ? rawOdemeDurum
        : int.tryParse(rawOdemeDurum?.toString() ?? '0') ?? 0;

    final bool isApproved = odeme_durum == 1;
    final bool isPending = odeme_durum == 0;

    // Debug için console'a yazdır
    print('Ödeme ID: ${odeme['id']}, raw_durum: $rawOdemeDurum (${rawOdemeDurum.runtimeType}), parsed_durum: $odeme_durum, isApproved: $isApproved, isPending: $isPending');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: InkWell(
          onTap: () => _showOdemeDetail(odeme),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isApproved
                            ? Colors.green
                            : isPending
                            ? Colors.orange
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproved
                            ? Icons.check
                            : isPending
                            ? Icons.schedule
                            : Icons.close,
                        color: Colors.white,
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
                              Text(
                                '₺${_formatMoney(odeme['tutar'])}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Spacer(),
                              _buildStatusChip(odeme, isDark),
                            ],
                          ),
                          SizedBox(height: 4),
                          if (_isTeacher && odeme['kullanici'] != null)
                            Text(
                              odeme['kullanici']['adsoyad'] ?? odeme['kullanici']['name'] ?? 'İsimsiz',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  odeme['aciklama'] ?? 'Açıklama yok',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (odeme['MonthComment'] != null && odeme['MonthComment'].toString().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    odeme['MonthComment'],
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(odeme['created_at']),
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    Spacer(),
                    if (_isTeacher && isPending)
                      TextButton.icon(
                        onPressed: () => _approvePayment(odeme),
                        icon: Icon(Icons.check, size: 16),
                        label: Text('Onayla'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

    if (isApproved) {
      chipColor = Colors.green;
      chipText = 'Onaylandı';
    } else if (isPending) {
      chipColor = Colors.orange;
      chipText = 'Bekliyor';
    } else {
      chipColor = Colors.red;
      chipText = 'Reddedildi';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
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
      MaterialPageRoute(
        builder: (context) => AddPaymentPage(),
      ),
    ).then((_) => _refreshData());
  }

  void _showOdemeDetail(dynamic odeme) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailPage(
          odeme: odeme,
          isTeacher: _isTeacher,
        ),
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
        Uri.parse('${ApiConstants.baseUrl}/odemeler/${odeme['id']}'),
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