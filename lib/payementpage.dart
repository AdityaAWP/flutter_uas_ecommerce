import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/shipping_page.dart';

class PaymentPage extends StatefulWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> purchasedItems;
  const PaymentPage({
    super.key,
    required this.totalPrice,
    required this.purchasedItems,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _paymentController = TextEditingController();
  double? _paymentAmount;
  double _change = 0.0;
  String _errorMessage = '';
  late List<Map<String, dynamic>> _currentItems;
  late double _currentTotalPrice;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.purchasedItems);
    _currentTotalPrice = widget.totalPrice;
  }

  void _deleteItem(int index) {
    setState(() {
      _currentItems.removeAt(index);
      // Recalculate total price
      _currentTotalPrice = _currentItems.fold(
          0.0, (sum, item) => sum + (item['price'] * item['quantity']));
    });

    // When navigating back, pass both the remaining items and whether all items were deleted
    if (_currentItems.isEmpty) {
      Navigator.pop(context, {'clear': true});
    }
  }

  void _calculateChange() {
    setState(() {
      _paymentAmount = double.tryParse(_paymentController.text) ?? 0.0;

      if (_paymentAmount! < _currentTotalPrice) {
        _errorMessage = 'Jumlah Uang Anda Kurang';
        _change = 0.0;
      } else {
        _errorMessage = '';
        _change = _paymentAmount! - _currentTotalPrice;
      }
    });
  }

  void _printReceipt() {
    if (_errorMessage.isNotEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Total Harga: Rp. ${_currentTotalPrice.toStringAsFixed(0)}'),
                Text(
                    'Jumlah Uang Anda: Rp. ${_paymentAmount?.toStringAsFixed(0) ?? '0'}'),
                Text('Kembalian: Rp. ${_change.toStringAsFixed(0)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(true); // Return to home with true result
              },
              child: const Text('Print'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _purchaseItems() async {
    if (_errorMessage.isNotEmpty) {
      return;
    }

    // Navigate to shipping page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShippingPage(
          totalPrice: _currentTotalPrice,
          purchasedItems: _currentItems,
        ),
      ),
    );

    if (result != null) {
      // Handle the shipping selection
      Map<String, dynamic> shippingData = result as Map<String, dynamic>;
      double shippingCost = shippingData['shipping_cost'].toDouble();

      // Update total price with shipping cost
      setState(() {
        _currentTotalPrice += shippingCost;
      });

      // Continue with purchase process...
      _processPurchase(shippingData);
    }
  }

  void _processPurchase(Map<String, dynamic> shippingData) async {
    // Retrieve token from shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');

    // Prepare data for the order
    final orderData = {
      'total_price': _currentTotalPrice,
      'shipping_cost': shippingData['shipping_cost'],
      'shipping_service': shippingData['shipping_service'],
      'estimated_days': shippingData['estimated_days'],
      'products': _currentItems.map((item) {
        return {
          'id': item['id'],
          'quantity': item['quantity'],
          'price': item['price'],
        };
      }).toList(),
    };

    // Send data to the server
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(orderData),
    );

    if (response.statusCode == 201) {
      // Order successful
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Order placed successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pop(true); // Return to home with true result
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Log the response body for debugging
      print('Failed to place order: ${response.body}');

      // Order failed
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to place order.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF243642),
      appBar: AppBar(
        title: const Text('Pembayaran', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF243642),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF387478),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Rp. ${_currentTotalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F1E7),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daftar Pembelian:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF243642),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._currentItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name']} (x${item['quantity']})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF243642),
                                ),
                              ),
                            ),
                            Text(
                              'Rp. ${(item['price'] * item['quantity']).toString()}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF243642),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteItem(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _purchaseItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF243642),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Beli',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE2F1E7),
                    ),
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
