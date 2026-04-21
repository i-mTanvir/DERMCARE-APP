import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/doctor_bottom_nav_bar.dart';

class DoctorBookingsScreen extends StatelessWidget {
  const DoctorBookingsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return const Color(0xFFB26A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = context.read<AuthService>().userId;
    final db = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Doctor Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: db.getDoctorAppointments(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load bookings\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final items = snapshot.data ?? const <AppointmentModel>[];
          if (items.isEmpty) {
            return const Center(child: Text('No bookings found yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final appt = items[i];
              final color = _statusColor(appt.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Patient ID: ${appt.userId.substring(0, appt.userId.length >= 8 ? 8 : appt.userId.length)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            appt.status.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Date: ${appt.date}'),
                    Text('Time: ${appt.time}'),
                    const SizedBox(height: 12),
                    if (appt.status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => db.updateAppointmentStatus(
                                appointmentId: appt.id,
                                status: 'confirmed',
                              ),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => db.updateAppointmentStatus(
                                appointmentId: appt.id,
                                status: 'cancelled',
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                              ),
                              child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const DoctorBottomNavBar(currentIndex: 1),
    );
  }
}
