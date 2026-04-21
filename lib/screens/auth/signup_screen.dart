import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _specialistCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _role = 'patient';
  String _gender = 'male';

  bool get _isDoctor => _role == 'doctor';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _licenseCtrl.dispose();
    _designationCtrl.dispose();
    _specialistCtrl.dispose();
    _ageCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await context.read<AuthService>().signUp(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
          role: _role,
          licenseNumber: _licenseCtrl.text,
          designation: _designationCtrl.text,
          specialist: _specialistCtrl.text,
          gender: _gender,
          age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
          description: _descriptionCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      context.go(_isDoctor ? '/doctor/home' : '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create patient or doctor account',
                  style: TextStyle(fontSize: 14, color: AppColors.greyText),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4DCEC)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _roleSegment(
                          label: 'Patient',
                          selected: _role == 'patient',
                          onTap: () => setState(() => _role = 'patient'),
                          isLeft: true,
                        ),
                      ),
                      Expanded(
                        child: _roleSegment(
                          label: 'Doctor',
                          selected: _role == 'doctor',
                          onTap: () => setState(() => _role = 'doctor'),
                          isLeft: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: Validators.validateName,
                ),
                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                if (!_isDoctor) ..._passwordFields(),
                if (_isDoctor) ...[
                  CustomTextField(
                    controller: _licenseCtrl,
                    label: 'License Number',
                    hint: 'Enter medical license number',
                    icon: Icons.verified_user_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'License number is required'
                        : null,
                  ),
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
                    initialValue: _gender,
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
                        borderSide: const BorderSide(
                            color: Color(0xFFDEE4F0), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionCtrl,
                    label: 'Description',
                    hint: 'Write your profile description',
                    icon: Icons.notes_outlined,
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  ..._passwordFields(),
                ],
                const SizedBox(height: 8),
                CustomButton(
                    text: 'Create Account',
                    onPressed: _signup,
                    isLoading: _loading),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                                color: AppColors.greyText, fontSize: 14),
                          ),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? const Radius.circular(13) : Radius.zero,
        right: isLeft ? Radius.zero : const Radius.circular(13),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(13) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(13),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontSize: 32 / 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _passwordFields() {
    return [
      CustomTextField(
        controller: _passCtrl,
        label: 'Password',
        hint: 'Min. 6 characters',
        icon: Icons.lock_outline,
        obscureText: _obscurePass,
        validator: Validators.validatePassword,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePass ? Icons.visibility_off : Icons.visibility,
            color: AppColors.greyText,
          ),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ),
      ),
      CustomTextField(
        controller: _confirmCtrl,
        label: 'Confirm Password',
        hint: 'Re-enter password',
        icon: Icons.lock_outline,
        obscureText: _obscureConfirm,
        validator: (v) => Validators.validateConfirmPassword(v, _passCtrl.text),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: AppColors.greyText,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
    ];
  }
}
