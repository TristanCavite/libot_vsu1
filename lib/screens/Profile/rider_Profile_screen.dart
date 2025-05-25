import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';

class RiderProfileScreen extends StatefulWidget {
  final String? userId; // ✅ ADDED: optional userId to view another rider
  final bool viewOnly;  // ✅ ADDED: disables editing if true

  const RiderProfileScreen({
    super.key,
    this.userId,
    this.viewOnly = false,
  });

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _courseYearController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();

  String fullName = '';
  String email = '';
  String profileUrl = '';
  String studentIdUrl = '';
  String driversLicenseUrl = '';
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    
  final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid; // ✅ EDITED
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        fullName = data['fullName'] ?? '';
        email = data['email'] ?? '';
        profileUrl = data['profileUrl'] ?? '';
        studentIdUrl = data['studentIdUrl'] ?? '';
        driversLicenseUrl = data['driversLicenseUrl'] ?? '';
        _mobileController.text = data['mobile'] ?? '';
        _addressController.text = data['address'] ?? '';
        _studentIdController.text = data['studentId'] ?? '';
        _courseYearController.text = data['courseYear'] ?? '';
        _vehicleController.text = data['vehicle'] ?? '';
      });
    }
  }

  Future<String?> _uploadFile(String folderName) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final file = File(pickedFile.path);
    final fileBytes = await file.readAsBytes();
    final contentType = lookupMimeType(file.path);
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

    if (firebaseUid == null) {
      print("Error: Firebase user not found.");
      return null;
    }

    final filePath = '$folderName/$firebaseUid/profile.jpg';

    try {
      await Supabase.instance.client.storage
          .from('user-uploads')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final url = Supabase.instance.client.storage
          .from('user-uploads')
          .getPublicUrl(filePath);

      return '$url?ts=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (widget.viewOnly) return; // ✅ ADDED
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'mobile': _mobileController.text.trim(),
      'address': _addressController.text.trim(),
      'studentId': _studentIdController.text.trim(),
      'courseYear': _courseYearController.text.trim(),
      'vehicle': _vehicleController.text.trim(),
    });

    setState(() => isEditing = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00843D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            if (!widget.viewOnly && !isEditing) // <-- ADD THIS CONDITION
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            const Spacer(),
                            if (!widget.viewOnly && !isEditing)
                              TextButton(
                                onPressed:
                                    () => setState(() => isEditing = true),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 60),
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                80,
                                24,
                                60,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Rider',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'My account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    TextFormField(
                                      controller: _studentIdController,
                                       readOnly: widget.viewOnly || !isEditing,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Student ID',
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Please enter Student ID'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _mobileController,
                                       readOnly: widget.viewOnly || !isEditing,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Contact Number',
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Please enter Contact Number'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _courseYearController,
                                       readOnly: widget.viewOnly || !isEditing,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Course & Year',
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Please enter Course & Year'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _addressController,
                                       readOnly: widget.viewOnly || !isEditing,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Address',
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Please enter Address'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _vehicleController,
                                       readOnly: widget.viewOnly || !isEditing,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Vehicle',
                                        labelStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      value.trim().isEmpty
                                                  ? 'Please enter Vehicle Info'
                                                  : null,
                                    ),
                                    const SizedBox(height: 12),

                                    /// Student ID Upload section
                                    _buildUploadSection(
                                      'Student ID Photo',
                                      studentIdUrl,
                                      'student_ids',
                                    ),
                                    const SizedBox(height: 12),

                                    /// Driver's License Upload section
                                    _buildUploadSection(
                                      "Driver's License Photo",
                                      driversLicenseUrl,
                                      'drivers_license',
                                    ),

                                    const SizedBox(height: 20),
                                    if (!widget.viewOnly && isEditing)
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _saveProfile();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF00A651,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Save Profile',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage:
                                        profileUrl.isNotEmpty
                                            ? NetworkImage(profileUrl)
                                            : null,
                                    backgroundColor: Colors.grey[300],
                                    child:
                                        profileUrl.isEmpty
                                            ? const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                  if (!widget.viewOnly && isEditing)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final url = await _uploadFile(
                                            'profile_pics',
                                          );
                                          if (url != null) {
                                            final uid =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid;
                                            if (uid != null) {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(uid)
                                                  .update({'profileUrl': url});
                                              setState(() => profileUrl = url);
                                            }
                                          }
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 20,
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadSection(String label, String imageUrl, String folderName) {
    return imageUrl.isEmpty
        ? ElevatedButton(
          onPressed: widget.viewOnly || !isEditing // ✅ ADDED
                ? null
                  : () async {
                    final url = await _uploadFile(folderName);
                    if (url != null) {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                            folderName == 'student_ids'
                                    ? 'studentIdUrl'
                                    : 'driversLicenseUrl':
                                url,
                          });
                      setState(() {
                        if (folderName == 'student_ids') {
                          studentIdUrl = url;
                        } else {
                          driversLicenseUrl = url;
                        }
                      });
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Upload $label',
            style: const TextStyle(color: Colors.black87),
          ),
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                   if (!widget.viewOnly && isEditing)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          final url = await _uploadFile(folderName);
                          if (url != null) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                                  folderName == 'student_ids'
                                          ? 'studentIdUrl'
                                          : 'driversLicenseUrl':
                                      url,
                                });
                            setState(() {
                              if (folderName == 'student_ids') {
                                studentIdUrl = url;
                              } else {
                                driversLicenseUrl = url;
                              }
                            });
                          }
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
  }
}
