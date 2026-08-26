import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const BaranApp());
}

class BaranApp extends StatelessWidget {
  const BaranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baran Link',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tahoma', // در صورت تمایل می‌توانید فونت دیگری اضافه کنید
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: const Color(0xFFFF5722), // رنگ نارنجی اختصاصی مشابه اکسپرس
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _licenseController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showWebView = false;
  late final WebViewController _webViewController;

  // تابع پاک‌سازی کش مرورگر و بازگشت به صفحه ورود
  Future<void> _resetAndClearCache() async {
    final WebViewCookieManager cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
    
    setState(() {
      _showWebView = false;
      _licenseController.clear();
      _errorMessage = '';
    });
  }

  Future<void> _processLogin() async {
    final license = _licenseController.text.trim();

    if (!license.startsWith('BARANLINK')) {
      setState(() {
        _errorMessage = 'لطفاً لایسنس معتبر وارد کنید (شروع با BARANLINK).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://baranlink.cyou/api/BaranToken/$license'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool success = data['success'] ?? false;
        final String accessToken = data['access_token'] ?? '';

        if (success && accessToken.isNotEmpty) {
          final ssoLink =
              'https://snapp.market/?source=jek_pwa-food&food_service_design=new&token=$accessToken&sso_channel=food';
          
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(ssoLink));

          setState(() {
            _showWebView = true;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'لایسنس وارد شده نامعتبر یا منقضی شده است.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'بررسی وضعیت لایسنس با مشکل مواجه شد. لطفاً دوباره تلاش کنید.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ارتباط با سیستم برقرار نشد، لطفاً اینترنت خود را بررسی کنید.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------
    // نمای وب‌ویو (پس از ورود موفق)
    // ---------------------------------------------------------
    if (_showWebView) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          title: const Text(
            'پنل اختصاصی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton.icon(
              onPressed: _resetAndClearCache,
              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 20),
              label: const Text(
                'پاک‌سازی و خروج',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: WebViewWidget(controller: _webViewController),
        ),
      );
    }

    // ---------------------------------------------------------
    // نمای صفحه لاگین (دریافت لایسنس)
    // ---------------------------------------------------------
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'باران لینک',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ورود سریع و امن با لایسنس اختصاصی',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBinding(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لایسنس خود را وارد کنید',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'برای ورود به پنل، کلید لایسنس خریداری شده خود را در کادر زیر قرار دهید.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _licenseController,
                          enabled: !_isLoading,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: 'BARANLINK-XXXX-XXXX',
                            hintTextDirection: TextDirection.ltr,
                            prefixIcon: const Icon(Icons.vpn_key_rounded),
                            suffixIcon: _licenseController.text.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                    onPressed: () {
                                      _licenseController.clear();
                                      setState(() { _errorMessage = ''; });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                          ),
                          onChanged: (text) => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _processLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBinding(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                  )
                                : const Text('بررسی لایسنس و ورود', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: BorderSide(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, size: 16, color: Colors.black38),
                    SizedBox(width: 6),
                    Text(
                      'تمامی فرآیندهای ورود از طریق ارتباط رمزنگاری‌شده انجام می‌پذیرد.',
                      style: TextStyle(fontSize: 11, color: Colors.black38),
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
}
