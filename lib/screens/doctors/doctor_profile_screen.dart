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
        const SnackBar(
          content: Text('Doctor profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showLogoutDialog() async {
    final auth = context.read<AuthService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of DermCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.greyText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.logout();
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(28)),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white24,
                              child: const Icon(Icons.medical_services,
                                  size: 46, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              auth.displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              auth.email,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Doctor Profile',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Professional Details'),
                      _formCard(
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _designationCtrl,
                              label: 'Designation',
                              hint: 'e.g. Consultant Dermatologist',
                              icon: Icons.badge_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Designation is required'
                                  : null,
                            ),
                            CustomTextField(
                              controller: _specialistCtrl,
                              label: 'Specialist',
                              hint: 'e.g. Clinical Dermatology',
                              icon: Icons.medical_services_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Specialist is required'
                                  : null,
                            ),
                            CustomTextField(
                              controller: _licenseCtrl,
                              label: 'License Number',
                              hint: 'Enter license number',
                              icon: Icons.verified_user_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'License number is required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _sectionLabel('Personal Details'),
                      _formCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _ageCtrl,
                              label: 'Age',
                              hint: 'Enter age',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final age = int.tryParse((v ?? '').trim());
                                if (age == null || age < 22)
                                  return 'Enter valid age';
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
                              initialValue: _gender,
                              items: const [
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _gender = v ?? 'male'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.inputBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFDEE4F0), width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFDEE4F0), width: 1.5),
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
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Description is required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CustomButton(
                          text: 'Save Doctor Profile',
                          onPressed: _save,
                          isLoading: _saving,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const DoctorBottomNavBar(currentIndex: 2),
    );
  }

  static Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.greyText,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  static Widget _formCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
