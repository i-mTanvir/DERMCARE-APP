import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/doctor_bottom_nav_bar.dart';

class DoctorBookingsScreen extends StatefulWidget {
  const DoctorBookingsScreen({super.key});

  @override
  State<DoctorBookingsScreen> createState() => _DoctorBookingsScreenState();
}

class _DoctorBookingsScreenState extends State<DoctorBookingsScreen> {
  final Map<String, String> _statusOverrides = {};
  final Set<String> _updatingIds = {};

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'accepted':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return const Color(0xFFB26A00);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
      case 'accepted':
        return 'ACCEPTED';
      case 'cancelled':
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  }

  Future<void> _updateStatus({
    required FirestoreService db,
    required String appointmentId,
    required String currentStatus,
    required String nextStatus,
  }) async {
    setState(() {
      _statusOverrides[appointmentId] = nextStatus;
      _updatingIds.add(appointmentId);
    });

    try {
      await db.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: nextStatus,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusOverrides[appointmentId] = currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingIds.remove(appointmentId);
        });
      }
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
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
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
              final effectiveStatus = _statusOverrides[appt.id] ?? appt.status;
              final color = _statusColor(effectiveStatus);
              final isUpdating = _updatingIds.contains(appt.id);
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(effectiveStatus),
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
                    if (effectiveStatus == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isUpdating
                                  ? null
                                  : () => _updateStatus(
                                        db: db,
                                        appointmentId: appt.id,
                                        currentStatus: appt.status,
                                        nextStatus: 'confirmed',
                                      ),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success),
                              child: isUpdating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Accept',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isUpdating
                                  ? null
                                  : () => _updateStatus(
                                        db: db,
                                        appointmentId: appt.id,
                                        currentStatus: appt.status,
                                        nextStatus: 'cancelled',
                                      ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                              ),
                              child: const Text('Reject',
                                  style: TextStyle(color: AppColors.error)),
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
