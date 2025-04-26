import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // date formatting

class RequestDeliveryScreen extends StatefulWidget {
  const RequestDeliveryScreen({super.key});

  @override
  State<RequestDeliveryScreen> createState() => _RequestDeliveryScreenState();
}

class _RequestDeliveryScreenState extends State<RequestDeliveryScreen> {
  // Controllers for text fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Selected pickup option
  String _selectedPickupOption = 'Now';

  @override
  void initState() {
    super.initState();
    // Set current date and time
    if (_selectedPickupOption == 'Now') {
      _setCurrentDateTime();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Method to set current date and time
  void _setCurrentDateTime() {
    final now = DateTime.now();
    _dateController.text = DateFormat('MMM d, yyyy').format(now);
    _timeController.text = DateFormat('h:mm a').format(now);
  }

  // Method to clear date and time fields
  void _clearDateTime() {
    _dateController.clear();
    _timeController.clear();
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00843D)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  // Show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00843D)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      setState(() {
        _timeController.text = DateFormat('h:mm a').format(selectedDateTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your orders here...',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            //Matic ata ning destination ngari or need pani iclick pero rag dili ni text ari guro
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.circle_rounded,
                  color: Color(0xFF424242),
                  size: 15,
                ),
                hintText: 'Destination',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Need logic para automatic na ma fill and exact fee
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.attach_money_outlined,
                  color: Colors.black,
                ),
                hintText: 'Delivery fee: 0',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            // Insert mapa ari
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/map_placeholder.png',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Pickup time
            const SizedBox(height: 16),
            const Text(
              'Pickup Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPickupOption = 'Now';
                        _setCurrentDateTime();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            _selectedPickupOption == 'Now'
                                ? const Color(0xFF00843D)
                                : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Now',
                        style: TextStyle(
                          color:
                              _selectedPickupOption == 'Now'
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedPickupOption == 'Schedule'
                              ? const Color(0xFF00843D)
                              : const Color(0xFFF5F5F5),
                      foregroundColor:
                          _selectedPickupOption == 'Schedule'
                              ? Colors.white
                              : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedPickupOption = 'Schedule';
                        _clearDateTime();
                      });
                    },
                    child: const Text('Schedule'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'Date',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              readOnly: true,
              onTap: () => _selectTime(context),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.access_time),
                hintText: 'Time',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            //Payment method
            const SizedBox(height: 16),
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.account_balance_wallet_outlined),
                ),
                value: 'Cash',
                items:
                    ['Cash', 'GCash', 'Credit Card']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) {},
              ),
            ),

            // Bottom button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00843D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Handle delivery request confirmation here
                  // Add logic to send the request
                },
                child: const Text(
                  'Confirm Delivery Request',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
