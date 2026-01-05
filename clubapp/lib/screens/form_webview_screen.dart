import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';

class FormWebViewScreen extends StatefulWidget {
  static const route = '/form-webview';
  final String url;

  const FormWebViewScreen({super.key, required this.url});

  @override
  State<FormWebViewScreen> createState() => _FormWebViewScreenState();
}

class _FormWebViewScreenState extends State<FormWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _autoFillForm();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _autoFillForm() async {
    final profile = await ProfileService().getProfile();
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    
    // JS Injection script
    final String jsCode = """
      setTimeout(() => {
        const profile = {
          name: "${profile['name']}",
          email: "$userEmail",
          reg_no: "${profile['reg_no']}"
        };

        const items = document.querySelectorAll('div[role="listitem"]');
        items.forEach(item => {
          const text = item.innerText.toLowerCase();
          const input = item.querySelector('input, textarea');
          if (!input) return;

          let valueToSet = null;
          if (text.includes('name')) valueToSet = profile.name;
          else if (text.includes('email')) valueToSet = profile.email;
          else if (text.includes('reg') || text.includes('id number') || text.includes('roll')) valueToSet = profile.reg_no;

          if (valueToSet && valueToSet !== "null" && valueToSet !== "") {
            input.value = valueToSet;
            input.dispatchEvent(new Event('input', { bubbles: true }));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            input.dispatchEvent(new Event('blur', { bubbles: true }));
          }
        });
      }, 1500);
    """;

    try {
      await _controller.runJavaScript(jsCode);
    } catch (e) {
      debugPrint("Error injecting JS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register for Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
