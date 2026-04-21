import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/doctor_bottom_nav_bar.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final db = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: db.getDoctorAppointments(auth.userId),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          final pending = items.where((e) => e.status == 'pending').length;
          final confirmed = items.where((e) => e.status == 'confirmed').length;
          final cancelled = items.where((e) => e.status == 'cancelled').length;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Dr. ${auth.displayName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your booking requests and profile information.',
                  style: TextStyle(fontSize: 13, color: AppColors.greyText),
                ),
                const SizedBox(height: 20),
                _statCard('Pending', pending, const Color(0xFFFFF4DB), const Color(0xFFB26A00)),
                const SizedBox(height: 10),
                _statCard('Confirmed', confirmed, const Color(0xFFE7F8EC), AppColors.success),
                const SizedBox(height: 10),
                _statCard('Cancelled', cancelled, const Color(0xFFFDEAEA), AppColors.error),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const DoctorBottomNavBar(currentIndex: 0),
    );
  }

  Widget _statCard(String label, int value, Color bg, Color text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: text,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              color: text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
