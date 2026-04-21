import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final today =
        MaterialLocalizations.of(context).formatFullDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: db.getDoctorAppointments(auth.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load dashboard data',
                style: TextStyle(color: AppColors.error),
              ),
            );
          }

          final items = snapshot.data ?? const [];
          final pending = items.where((e) => e.status == 'pending').length;
          final confirmed = items.where((e) => e.status == 'confirmed').length;
          final cancelled = items.where((e) => e.status == 'cancelled').length;
          final total = items.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0D47A1),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Dr. ${auth.displayName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        today,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFE3F2FD)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Manage patient requests, track decisions, and keep your profile up to date.',
                        style: TextStyle(
                            fontSize: 14, height: 1.4, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: Text(
                          '$total total bookings',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Today\'s Snapshot',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 760
                        ? 3
                        : width > 500
                            ? 2
                            : 1;
                    const spacing = 12.0;
                    final tileWidth =
                        (width - (spacing * (crossAxisCount - 1))) /
                            crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _statCard(
                            label: 'Pending',
                            value: pending,
                            bg: const Color(0xFFFFF4DB),
                            text: const Color(0xFFB26A00),
                            icon: Icons.pending_actions_rounded,
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _statCard(
                            label: 'Confirmed',
                            value: confirmed,
                            bg: const Color(0xFFE7F8EC),
                            text: AppColors.success,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _statCard(
                            label: 'Cancelled',
                            value: cancelled,
                            bg: const Color(0xFFFDEAEA),
                            text: AppColors.error,
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go('/doctor/bookings'),
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('View Bookings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/doctor/profile'),
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: Color(0xFF90CAF9)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const DoctorBottomNavBar(currentIndex: 0),
    );
  }

  Widget _statCard({
    required String label,
    required int value,
    required Color bg,
    required Color text,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: text.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: text.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: text, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              color: text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
