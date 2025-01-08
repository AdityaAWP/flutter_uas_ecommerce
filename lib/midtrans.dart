import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'upload_bukti_page.dart';

class MidtransPaymentPage extends StatefulWidget {
  final String snapToken;
  final String redirectUrl;
  final int orderId; // Add orderId parameter

  const MidtransPaymentPage({
    Key? key,
    required this.snapToken,
    required this.redirectUrl,
    required this.orderId, // Add orderId parameter
  }) : super(key: key);

  @override
  State<MidtransPaymentPage> createState() => _MidtransPaymentPageState();
}

class _MidtransPaymentPageState extends State<MidtransPaymentPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(widget.redirectUrl),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Handle navigation to success/failure URLs
            if (request.url.contains('success')) {
              // Handle success
              Navigator.pop(context, 'success');
              return NavigationDecision.prevent;
            }
            if (request.url.contains('failure')) {
              // Handle failure
              Navigator.pop(context, 'failure');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _navigateToUploadBuktiPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UploadBuktiPage(orderId: widget.orderId), // Use actual order ID
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, 'canceled'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _navigateToUploadBuktiPage,
              child: const Text('Upload Bukti Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }
}
