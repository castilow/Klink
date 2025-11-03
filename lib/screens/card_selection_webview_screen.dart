import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/theme/app_theme.dart';

class CardSelectionWebViewScreen extends StatefulWidget {
  const CardSelectionWebViewScreen({super.key});

  @override
  State<CardSelectionWebViewScreen> createState() => _CardSelectionWebViewScreenState();
}

class _CardSelectionWebViewScreenState extends State<CardSelectionWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onHttpError: (HttpResponseError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('http://localhost:3000/add-card'));
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse('http://localhost:3000/add-card'));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Get.back();
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
              border: isDarkMode
                  ? Border.all(
                      color: const Color(0xFF404040).withOpacity(0.6),
                      width: 1,
                    )
                  : null,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
              size: 18,
            ),
          ),
        ),
        title: Text(
          'Tarjetas',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _hasError
          ? _buildErrorState(isDarkMode)
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) _buildLoadingState(isDarkMode),
              ],
            ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF000000) : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando tarjetas...',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF000000) : Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
              ),
              const SizedBox(height: 24),
              Text(
                'Error al cargar',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No se pudo conectar con el servidor de tarjetas.\nAsegúrate de que la aplicación Next.js esté ejecutándose en localhost:3000',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDarkMode
                        ? BorderSide(
                            color: const Color(0xFF404040).withOpacity(0.6),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Get.back();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}