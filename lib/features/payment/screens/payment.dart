import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreditCardPaymentPage extends StatefulWidget {
  final String packageTitle;
  final double amount;
  final Color packageColor;

  const CreditCardPaymentPage({
    Key? key,
    required this.packageTitle,
    required this.amount,
    required this.packageColor,
  }) : super(key: key);

  @override
  _CreditCardPaymentPageState createState() => _CreditCardPaymentPageState();
}

class _CreditCardPaymentPageState extends State<CreditCardPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isLoading = false;
  String _cardType = '';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ödeme',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(theme, isDark),
                  SizedBox(height: 24),
                  _buildCardPreview(isDark),
                  SizedBox(height: 24),
                  _buildCardForm(theme, isDark),
                  SizedBox(height: 24),
                  _buildSecurityNote(isDark),
                  SizedBox(height: 24),
                  _buildPayButton(theme),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.packageColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.packageColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: widget.packageColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.packageTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Toplam Tutar',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₺${widget.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: widget.packageColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardGradient(),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.credit_card, color: Colors.white, size: 32),
                _buildCardTypeLogo(),
              ],
            ),
            Text(
              _formatCardNumberDisplay(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KART SAHİBİ',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      _cardHolderController.text.isEmpty
                          ? 'AD SOYAD'
                          : _cardHolderController.text.toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SON KULLANMA',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      _expiryController.text.isEmpty
                          ? 'AA/YY'
                          : _expiryController.text,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getCardGradient() {
    switch (_cardType) {
      case 'visa':
        return [Color(0xFF1A1F71), Color(0xFF2E3B8C)];
      case 'mastercard':
        return [Color(0xFFEB001B), Color(0xFFF79E1B)];
      case 'troy':
        return [Color(0xFF00A651), Color(0xFF006837)];
      default:
        return [Color(0xFF2C3E50), Color(0xFF4A5568)];
    }
  }

  Widget _buildCardTypeLogo() {
    switch (_cardType) {
      case 'visa':
        return Text('VISA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic));
      case 'mastercard':
        return Row(
          children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            Transform.translate(offset: Offset(-8, 0), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.8), shape: BoxShape.circle))),
          ],
        );
      case 'troy':
        return Text('TROY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
      default:
        return SizedBox();
    }
  }

  String _formatCardNumberDisplay() {
    String number = _cardNumberController.text.replaceAll(' ', '');
    if (number.isEmpty) return '•••• •••• •••• ••••';

    String display = '';
    for (int i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) display += ' ';
      display += i < number.length ? number[i] : '•';
    }
    return display;
  }

  void _detectCardType(String number) {
    String cleanNumber = number.replaceAll(' ', '');
    setState(() {
      if (cleanNumber.startsWith('4')) {
        _cardType = 'visa';
      } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
        _cardType = 'mastercard';
      } else if (cleanNumber.startsWith('9')) {
        _cardType = 'troy';
      } else {
        _cardType = '';
      }
    });
  }

  Widget _buildCardForm(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kart Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Kart Numarası
            _buildTextField(
              controller: _cardNumberController,
              label: 'Kart Numarası',
              hint: '1234 5678 9012 3456',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              onChanged: (value) {
                _detectCardType(value);
                setState(() {});
              },
              validator: (value) {
                if (value == null || value.replaceAll(' ', '').length < 16) {
                  return 'Geçerli bir kart numarası girin';
                }
                return null;
              },
              theme: theme,
              isDark: isDark,
            ),
            SizedBox(height: 16),

            // Son Kullanma & CVV
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: 'Son Kullanma',
                    hint: 'AA/YY',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.length < 5) {
                        return 'Geçersiz';
                      }
                      return null;
                    },
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hint: '123',
                    icon: Icons.lock,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (value) {
                      if (value == null || value.length < 3) {
                        return 'Geçersiz';
                      }
                      return null;
                    },
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Kart Sahibi
            _buildTextField(
              controller: _cardHolderController,
              label: 'Kart Sahibinin Adı',
              hint: 'AD SOYAD',
              icon: Icons.person,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kart sahibi adı gerekli';
                }
                return null;
              },
              theme: theme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: isDark ? Colors.grey[800]?.withOpacity(0.3) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.packageColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Güvenli Ödeme', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text(
                  '256-bit SSL şifreleme ile korunmaktadır.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.packageColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 20),
            SizedBox(width: 8),
            Text(
              '₺${widget.amount.toStringAsFixed(0)} Öde',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Test aşaması simülasyonu
    await Future.delayed(Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Test bildirimi göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.info_outline,
          color: Colors.orange,
          size: 48,
        ),
        title: Text('Test Aşaması'),
        content: Text(
          'Kredi kartı ile ödeme şu an test aşamasındadır.\n\nÖdemeniz kaydedildi, eğitmeniniz tarafından onaylanacaktır.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog kapat
                Navigator.pop(context, true); // Sayfadan çık
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.packageColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }}

// Kart numarası formatlayıcı
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += text[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Son kullanma tarihi formatlayıcı
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    if (text.length > 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}