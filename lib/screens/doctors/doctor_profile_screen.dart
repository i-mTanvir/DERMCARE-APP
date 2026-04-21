import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/doctor_bottom_nav_bar.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _designationCtrl = TextEditingController();
  final _specialistCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _gender = 'male';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _designationCtrl.dispose();
    _specialistCtrl.dispose();
    _ageCtrl.dispose();
    _licenseCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    final row = await context.read<AuthService>().getDoctorProfile();
    if (!mounted) return;
    if (row != null) {
      _designationCtrl.text = (row['designation'] ?? '').toString();
      _specialistCtrl.text = (row['specialty'] ?? '').toString();
      _ageCtrl.text = (row['age'] ?? '').toString();
      _licenseCtrl.text = (row['license_number'] ?? '').toString();
      _descriptionCtrl.text = (row['about'] ?? '').toString();
      final g = (row['gender'] ?? 'male').toString().toLowerCase();
      _gender = g == 'female' ? 'female' : 'male';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().updateDoctorProfile(
            designation: _designationCtrl.text,
            specialist: _specialistCtrl.text,
            gender: _gender,
            age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
            description: _descriptionCtrl.text,
            licenseNumber: _licenseCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor profile updated'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Doctor Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/welcome');
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(auth.email, style: const TextStyle(color: AppColors.greyText)),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _designationCtrl,
                      label: 'Designation',
                      hint: 'e.g. Consultant Dermatologist',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
                    ),
                    CustomTextField(
                      controller: _specialistCtrl,
                      label: 'Specialist',
                      hint: 'e.g. Clinical Dermatology',
                      icon: Icons.medical_services_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Specialist is required' : null,
                    ),
                    CustomTextField(
                      controller: _licenseCtrl,
                      label: 'License Number',
                      hint: 'Enter license number',
                      icon: Icons.verified_user_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'License number is required' : null,
                    ),
                    CustomTextField(
                      controller: _ageCtrl,
                      label: 'Age',
                      hint: 'Enter age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final age = int.tryParse((v ?? '').trim());
                        if (age == null || age < 22) return 'Enter valid age';
                        return null;
                      },
                    ),
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'male'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFDEE4F0), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionCtrl,
                      label: 'Description',
                      hint: 'Write doctor profile description',
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 4),
                    CustomButton(text: 'Save Doctor Profile', onPressed: _save, isLoading: _saving),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const DoctorBottomNavBar(currentIndex: 2),
    );
  }
}
