import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _frontendUrl = String.fromEnvironment(
  'WEB_APP_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class WebFrontendPage extends StatefulWidget {
  const WebFrontendPage({super.key});

  @override
  State<WebFrontendPage> createState() => _WebFrontendPageState();
}

class _WebFrontendPageState extends State<WebFrontendPage> {
  late final WebViewController controller;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C0E12))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                loading = true;
                error = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => loading = false);
          },
          onWebResourceError: (failure) {
            if (failure.isForMainFrame == true && mounted) {
              setState(() {
                loading = false;
                error =
                    'Could not connect to Smart Finance. Start the local server and try again.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_frontendUrl));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0C0E12),
    body: SafeArea(
      child: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFFB9C2CF),
                backgroundColor: Color(0xFF20232B),
              ),
            ),
          if (error != null)
            ColoredBox(
              color: const Color(0xFF0C0E12),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 36,
                        color: Color(0xFFB9C2CF),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF0EDE6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => controller.reload(),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
