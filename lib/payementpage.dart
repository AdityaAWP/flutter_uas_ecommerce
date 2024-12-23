import 'package:flutter/material.dart';

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
      // Subtract the item's price from total
      _currentTotalPrice -= _currentItems[index]['price'];
      // Remove the item from the list
      _currentItems.removeAt(index);
      // Recalculate change if payment amount exists
      if (_paymentAmount != null) {
        if (_paymentAmount! < _currentTotalPrice) {
          _errorMessage = 'Jumlah Uang Anda Kurang';
          _change = 0.0;
        } else {
          _errorMessage = '';
          _change = _paymentAmount! - _currentTotalPrice;
        }
      }
    });
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
              TextField(
                controller: _paymentController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Masukkan jumlah uang anda',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF387478),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _calculateChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF629584),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Hitung Kembalian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
                    Text(
                      'Total Harga: Rp. ${_paymentAmount?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                          fontSize: 18, color: Color(0xFF243642)),
                    ),
                    Text(
                      'Kembalian: Rp. ${_change.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            _change >= 0 ? const Color(0xFF243642) : Colors.red,
                        fontWeight:
                            _change >= 0 ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
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
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF243642),
                                ),
                              ),
                            ),
                            Text(
                              'Rp. ${item['price'].toString()}',
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
                onPressed: _printReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF243642),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Print Nota',
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
