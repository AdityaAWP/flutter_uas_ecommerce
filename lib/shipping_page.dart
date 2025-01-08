import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts/upload_bukti_page.dart';
import 'package:uts/midtrans.dart'; // Import MidtransPaymentPage
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

class ShippingPage extends StatefulWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> purchasedItems;

  const ShippingPage({
    Key? key,
    required this.totalPrice,
    required this.purchasedItems,
  }) : super(key: key);

  @override
  _ShippingPageState createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage> {
  static const String ORIGIN_CITY_ID = '31555'; // Semarang
  static const String ORIGIN_CITY_NAME = 'SEMARANG';
  static const String ORIGIN_PROVINCE = 'JAWA TENGAH';
  static const String ORIGIN_ADDRESS =
      'Jl. Pamularsih Bar. VIII No.4, RT.004/RW.09, Bojongsalaman, Kec. Semarang Barat, Kota Semarang, Jawa Tengah 50141';

  static const String baseUrl =
      'https://3289-103-246-107-4.ngrok-free.app'; // Add this constant

  List<Map<String, dynamic>> provinces = [];
  List<Map<String, dynamic>> cities = [];
  Map<String, dynamic>? selectedProvince;
  Map<String, dynamic>? selectedCity;
  List<Map<String, dynamic>> shippingCosts = [];
  bool isLoading = false;
  String? selectedCourier = 'jne';
  final List<String> couriers = ['jne', 'pos', 'tiki'];

  @override
  void initState() {
    super.initState();
    fetchProvinces();
  }

  Future<void> fetchProvinces() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Updated endpoint to match Laravel route
      final response = await http.get(
        Uri.parse('$baseUrl/api/shipping/provinces'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Province Response Status: ${response.statusCode}');
      print('Province Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> provincesList = json.decode(response.body);
        setState(() {
          provinces = List<Map<String, dynamic>>.from(provincesList);
          isLoading = false;
        });
        print('Provinces loaded: ${provinces.length}');
      } else {
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching provinces: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load provinces: $e')),
        );
      }
    }
  }

  Future<void> fetchCities(String provinceId) async {
    setState(() {
      isLoading = true;
      selectedCity = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Updated endpoint to match Laravel route
      final response = await http.get(
        Uri.parse('$baseUrl/api/shipping/cities?province_id=$provinceId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> citiesList = json.decode(response.body);
        setState(() {
          cities = List<Map<String, dynamic>>.from(citiesList);
          isLoading = false;
        });
        print('Cities loaded: ${cities.length}');
      } else {
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cities: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: $e')),
        );
      }
    }
  }

  Future<void> checkShippingCost() async {
    if (selectedCity == null || selectedCourier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select city and courier')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Updated to use Laravel backend endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/api/shipping/domestic-cost'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'origin': ORIGIN_CITY_ID,
          'destination': selectedCity!['city_id'].toString(),
          'weight': '1000',
          'courier': selectedCourier,
          'price': 'lowest',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['meta']['status'] == 'success' &&
            responseData['data'] != null) {
          setState(() {
            shippingCosts =
                List<Map<String, dynamic>>.from(responseData['data']);
            isLoading = false;
          });
        } else {
          throw Exception(
              responseData['meta']['message'] ?? 'No shipping costs available');
        }
      } else {
        throw Exception('Failed to calculate shipping cost');
      }
    } catch (e) {
      print('Error checking shipping cost: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<int?> createOrder(Map<String, dynamic> shippingDetails) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Prepare the order data
      final orderData = {
        'products': widget.purchasedItems
            .map((item) => {
                  'id': item['id'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                })
            .toList(),
        'shipping_cost': shippingDetails['shipping_cost'],
        'shipping_destination': shippingDetails['shipping_destination'],
        'courier_service': shippingDetails['courier_service'],
        'estimated_days': shippingDetails['estimated_days'],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Order created with ID: ${responseData['data']['id']}');
        return responseData['data']['id'];
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e')),
        );
      }
      return null;
    }
  }

  Future<void> fetchMidtransToken(int orderId, double grossAmount) async {
    try {
      final String midtransServerKey = dotenv.env['MIDTRANS_SERVER_KEY']!;
      final String basicAuth =
          'Basic ' + base64Encode(utf8.encode(midtransServerKey + ':'));

      final response = await http.post(
        Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': basicAuth,
        },
        body: json.encode({
          "transaction_details": {
            "order_id": "ORDER-101-$orderId",
            "gross_amount": grossAmount,
          },
          "credit_card": {
            "secure": true,
          },
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final String token = responseData['token'];
        final String redirectUrl = responseData['redirect_url'];

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => MidtransPaymentPage(
            snapToken: token,
            redirectUrl: redirectUrl,
            orderId: orderId, // Pass the actual order ID
          ),
        ));
      } else {
        throw Exception(
            'Failed to fetch Midtrans token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Midtrans token: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch Midtrans token: $e')),
        );
      }
    }
  }

  void selectShippingService(Map<String, dynamic> service) {
    double shippingCost = double.parse(service['cost'].toString());
    double totalWithShipping = widget.totalPrice + shippingCost;

    // Create destination string from selected location
    String destination =
        '${selectedCity!['type']} ${selectedCity!['city_name']}, '
        '${selectedProvince!['province']}';

    final shippingDetails = {
      'shipping_cost': shippingCost,
      'shipping_destination': destination,
      'courier_service':
          '${selectedCourier!.toUpperCase()} - ${service['service']}',
      'estimated_days': service['etd'],
      'total_price': totalWithShipping,
      'description': service['description'],
    };

    // Create order with shipping details
    createOrder(shippingDetails).then((orderId) {
      if (orderId != null) {
        fetchMidtransToken(orderId, totalWithShipping);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Information'),
        backgroundColor: const Color(0xFF003161),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Origin information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shipping From:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('$ORIGIN_CITY_NAME, $ORIGIN_PROVINCE'),
                    const SizedBox(height: 4),
                    Text(
                      ORIGIN_ADDRESS,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Destination section title
            const Text(
              'Ship To:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Province Dropdown
            buildProvinceDropdown(),
            const SizedBox(height: 16),

            // City Dropdown
            buildCityDropdown(),
            const SizedBox(height: 16),

            // Courier Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Courier',
                border: OutlineInputBorder(),
              ),
              value: selectedCourier,
              items: couriers.map((String courier) {
                return DropdownMenuItem<String>(
                  value: courier,
                  child: Text(courier.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedCourier = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Check Shipping Cost Button
            ElevatedButton(
              onPressed: checkShippingCost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003161),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Check Shipping Cost',
                style: TextStyle(color: Colors.white),
              ),
            ),

            // Shipping Costs List
            if (shippingCosts.isNotEmpty) ...[
              const Text(
                'Available Shipping Services:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shippingCosts.length,
                itemBuilder: (context, index) {
                  final service = shippingCosts[index];
                  final double shippingCost =
                      double.parse(service['cost'].toString());
                  final double totalWithShipping =
                      widget.totalPrice + shippingCost;

                  return Card(
                    child: ListTile(
                      title: Text(service['service']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated: ${service['etd']} days'),
                          Text(
                              'Shipping: Rp ${shippingCost.toStringAsFixed(0)}'),
                          Text(
                              'Total: Rp ${totalWithShipping.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () => selectShippingService(service),
                    ),
                  );
                },
              ),
            ],

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  // Update the province dropdown
  Widget buildProvinceDropdown() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provinces.isEmpty) {
      return const Text('No provinces available');
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      decoration: const InputDecoration(
        labelText: 'Select Province',
        border: OutlineInputBorder(),
      ),
      value: selectedProvince,
      items: provinces.map((province) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: province,
          child: Text(province['province']?.toString() ?? 'Unknown Province'),
        );
      }).toList(),
      onChanged: (Map<String, dynamic>? value) {
        print('Selected province: $value'); // Debug log
        setState(() {
          selectedProvince = value;
          selectedCity = null;
          cities.clear();
        });
        if (value != null && value['province_id'] != null) {
          print('Fetching cities for province ID: ${value['province_id']}');
          fetchCities(value['province_id'].toString());
        }
      },
      hint: const Text('Select a province'),
    );
  }

  // Update the city dropdown widget
  Widget buildCityDropdown() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedProvince == null) {
      return const Text('Please select a province first',
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cities in ${selectedProvince!['province']}:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          decoration: const InputDecoration(
            labelText: 'Select City',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          value: selectedCity,
          items: cities.map((city) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: city,
              child: Text(
                '${city['type']} ${city['city_name']} (${city['zip_code']})',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? value) {
            print('Selected city: $value'); // Debug log
            setState(() {
              selectedCity = value;
            });
          },
          hint: const Text('Select a city'),
          isExpanded: true,
        ),
      ],
    );
  }
}
