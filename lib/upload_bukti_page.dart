import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class UploadBuktiPage extends StatefulWidget {
  final int orderId;

  const UploadBuktiPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _UploadBuktiPageState createState() => _UploadBuktiPageState();
}

class _UploadBuktiPageState extends State<UploadBuktiPage> {
  File? _image;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;
  Map<String, dynamic>? orderDetails;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse(
            'https://3289-103-246-107-4.ngrok-free.app/api/orders/${widget.orderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Order Details Response Status: ${response.statusCode}');
      print('Order Details Response Body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          orderDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load order details: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load order details: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _showReceipt() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Receipt', style: pw.TextStyle(fontSize: 28)),
              pw.SizedBox(height: 20),
              pw.Text('Order ID: ${orderDetails!['id']}',
                  style: pw.TextStyle(fontSize: 22)),
              pw.Text(
                  'Total: Rp${double.parse(orderDetails!['total_price'].toString()).toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 22)),
              pw.SizedBox(height: 20),
              pw.Text('Shipping Details:',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('To: ${orderDetails!['shipping_destination']}',
                  style: pw.TextStyle(fontSize: 20)),
              pw.Text('Courier: ${orderDetails!['courier_service']}',
                  style: pw.TextStyle(fontSize: 20)),
              pw.Text(
                  'Estimated Delivery: ${orderDetails!['estimated_days']} days',
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Text('Products:',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.ListView.builder(
                itemCount: orderDetails!['details'].length,
                itemBuilder: (context, index) {
                  final detail = orderDetails!['details'][index];
                  final productPrice =
                      double.parse(detail['product_price'].toString());
                  final quantity = detail['product_quantity'] ?? 0;
                  final subtotal = productPrice * quantity;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          detail['product']['product_title'] ??
                              'Unknown Product',
                          style: pw.TextStyle(fontSize: 20)),
                      pw.Text(
                          'Quantity: $quantity x Rp${productPrice.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 20)),
                      pw.Text('Subtotal: Rp${subtotal.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                              fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_${orderDetails!['id']}.pdf");
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(path: file.path, file: file),
      ),
    );
  }

  Future<void> _downloadReceipt(File file) async {
    final output = await getExternalStorageDirectory();
    final newFile = File("${output!.path}/receipt_${orderDetails!['id']}.pdf");
    await newFile.writeAsBytes(await file.readAsBytes());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Receipt downloaded to ${newFile.path}')),
    );
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'https://3289-103-246-107-4.ngrok-free.app/api/orders/${widget.orderId}/upload-proof'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files
          .add(await http.MultipartFile.fromPath('order_proof', _image!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        print('Proof of payment uploaded successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proof of payment uploaded successfully')),
        );
        await _showReceipt(); // Show receipt after successful upload
      } else {
        var responseBody = await response.stream.bytesToString();
        print('Failed to upload proof of payment: ${response.statusCode}');
        print('Response body: $responseBody');
        throw Exception('Failed to upload proof of payment');
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload proof of payment: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Bukti Pembayaran'),
        backgroundColor: const Color(0xFF003161),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails == null
              ? const Center(child: Text('Failed to load order details'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Order Details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Order ID: ${orderDetails!['id']}'),
                              Text(
                                  'Total: Rp${double.parse(orderDetails!['total_price'].toString()).toStringAsFixed(0)}'),
                              const Divider(),
                              const Text(
                                'Shipping Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'To: ${orderDetails!['shipping_destination']}'),
                              Text(
                                  'Courier: ${orderDetails!['courier_service']}'),
                              Text(
                                  'Estimated Delivery: ${orderDetails!['estimated_days']} days'),
                              const Divider(),
                              const Text(
                                'Products',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: orderDetails!['details'].length,
                                itemBuilder: (context, index) {
                                  final detail =
                                      orderDetails!['details'][index];
                                  final productPrice = double.parse(
                                      detail['product_price'].toString());
                                  final quantity =
                                      detail['product_quantity'] ?? 0;
                                  final subtotal = productPrice * quantity;

                                  return ListTile(
                                    title: Text(detail['product']
                                            ['product_title'] ??
                                        'Unknown Product'),
                                    subtitle: Text(
                                      'Quantity: $quantity x Rp${productPrice.toStringAsFixed(0)}',
                                    ),
                                    trailing: Text(
                                      'Rp${subtotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _image == null
                          ? Text('No image selected.')
                          : Image.file(_image!),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text('Pick Image'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _uploadImage,
                        child: isLoading
                            ? CircularProgressIndicator()
                            : Text('Upload Image'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String path;
  final File file;

  const PdfViewerPage({Key? key, required this.path, required this.file})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              final output = await getExternalStorageDirectory();
              final newFile =
                  File("${output!.path}/receipt_${file.path.split('/').last}");
              await newFile.writeAsBytes(await file.readAsBytes());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Receipt downloaded to ${newFile.path}')),
              );
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}
