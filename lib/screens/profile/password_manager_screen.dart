import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
 
class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});
  @override State<PasswordManagerScreen> createState()
    => _PasswordManagerScreenState();
}
 
class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _currentCtrl   = TextEditingController();
  final _newCtrl       = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _loadingCurrent = false;
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
 
  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingCurrent = true);
    try {
      await context.read<AuthService>().changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!'),
          backgroundColor: AppColors.success));
      context.go('/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e'),
          backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loadingCurrent = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Password Manager', style: TextStyle(
          fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/profile')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'You must enter your current password to set a new one.',
                    style: TextStyle(fontSize: 13, color: AppColors.bodyText))),
                ]),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _currentCtrl,
                label: 'Current Password',
                hint: 'Enter current password',
                icon: Icons.lock_outline,
                obscureText: _obscureCurrent,
                validator: (v) => (v == null || v.isEmpty)
                  ? 'Current password is required' : null,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                    ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.greyText),
                  onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent)),
              ),
              CustomTextField(
                controller: _newCtrl,
                label: 'New Password',
                hint: 'Min. 6 characters',
                icon: Icons.lock_open_outlined,
                obscureText: _obscureNew,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'New password is required';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  if (v == _currentCtrl.text) {
                    return 'New password must differ from current password';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                    ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.greyText),
                  onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew)),
              ),
              CustomTextField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm new password';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                    ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.greyText),
                  onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm)),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Change Password',
                onPressed: _changePassword,
                isLoading: _loadingCurrent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
