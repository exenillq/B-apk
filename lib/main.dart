import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:url_launcher/url_launcher.dart';

// تونل امنیتی برای دور زدن خطاهای SSL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final httpClient = super.createHttpClient(context);
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    httpClient.idleTimeout = const Duration(seconds: 15);
    httpClient.connectionTimeout = const Duration(seconds: 15);
    return httpClient;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
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
        fontFamily: 'Tahoma',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: const Color(0xFFFF5722),
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
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _processLogin() async {
    String inputLink = _linkController.text.trim();

    if (inputLink.isEmpty) {
      setState(() {
        _errorMessage = 'لطفاً لینک اختصاصی خود را وارد کنید.';
      });
      return;
    }

    if (!inputLink.startsWith('http://') && !inputLink.startsWith('https://')) {
      inputLink = 'https://$inputLink';
    }

    Uri? targetUri = Uri.tryParse(inputLink);
    if (targetUri == null || !targetUri.hasAbsolutePath) {
      setState(() {
        _errorMessage = 'فرمت لینک وارد شده اشتباه است.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      client.connectionTimeout = const Duration(seconds: 15);
        
      final ioClient = IOClient(client);

      // ارسال درخواست مستقیماً به لینکی که کاربر وارد کرده است (بدون هیچ شرط و شروطی)
      final response = await ioClient.get(
        targetUri,
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Connection': 'keep-alive'
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool success = data['success'] ?? false;
        final String accessToken = data['access_token'] ?? '';

        if (success && accessToken.isNotEmpty) {
          final String ssoLink =
              'https://snapp.market/?source=jek_pwa-food&food_service_design=new&token=$accessToken&sso_channel=food';
          
          final Uri url = Uri.parse(ssoLink);
          
          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          } else {
             setState(() {
              _errorMessage = 'امکان باز کردن مرورگر در گوشی شما وجود ندارد.';
            });
          }
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'اطلاعات در لینک یافت نشد یا منقضی شده است.';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'لینک یافت نشد یا منقضی شده است (خطای 404).';
        });
      } else {
        setState(() {
          _errorMessage = 'ارتباط با لینک برقرار نشد (کد خطای سرور: ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطای ارتباط شبکه:\nلطفا از خاموش بودن فیلترشکن خود اطمینان حاصل کنید.\n\nجزئیات فنی: ${e.toString().split('(').first}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'ورود سریع و امن با لینک اختصاصی',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لینک خود را وارد کنید',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'برای ورود به فروشگاه، لینک اختصاصی ارسال شده برای خود را در کادر زیر قرار دهید.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _linkController,
                          enabled: !_isLoading,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: 'https://...',
                            hintTextDirection: TextDirection.ltr,
                            prefixIcon: const Icon(Icons.link_rounded),
                            suffixIcon: _linkController.text.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                    onPressed: () {
                                      _linkController.clear();
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                  )
                                : const Text('بررسی لینک و ورود', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    textDirection: _errorMessage.contains('Exception') || _errorMessage.contains('Error') ? TextDirection.ltr : TextDirection.rtl,
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
