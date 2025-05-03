import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final TextEditingController _placeNameController = TextEditingController();
  String _selectedCampusCategory = 'Upper Campus'; // Default selected

  Future<void> _addPlace() async {
    final placeName = _placeNameController.text.trim();
    if (placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place name is required!')));
      return;
    }

    await FirebaseFirestore.instance.collection('places').add({
      'name': placeName,
      'campusCategory': _selectedCampusCategory,
    });

    _placeNameController.clear(); // clear the field
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place added successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Place'),
        backgroundColor: const Color(0xFF00843D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _placeNameController,
              decoration: const InputDecoration(
                labelText: 'Place Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCampusCategory,
              decoration: const InputDecoration(
                labelText: 'Campus Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Upper Campus', child: Text('Upper Campus')),
                DropdownMenuItem(value: 'Lower Campus', child: Text('Lower Campus')),
                DropdownMenuItem(value: 'Outside', child: Text('Outside')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCampusCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPlace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00843D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Place'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
