import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  DateTime? _parseAppointmentDateTime(AppointmentModel appt) {
    final raw = '${appt.date} ${appt.time}'.trim();
    final patterns = [
      DateFormat('yyyy-MM-dd hh:mm a'),
      DateFormat('yyyy-MM-dd h:mm a'),
      DateFormat('yyyy-MM-dd HH:mm'),
    ];

    for (final pattern in patterns) {
      try {
        return pattern.parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  List<_PatientAlert> _buildAlerts(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final alerts = <_PatientAlert>[];

    for (final appt in appointments) {
      final status = appt.status.toLowerCase();
      final eventAt = appt.createdAt ?? now;

      if (status == 'confirmed' || status == 'accepted') {
        alerts.add(
          _PatientAlert(
            icon: Icons.check_circle,
            color: AppColors.success,
            title: 'Appointment Accepted',
            body:
                '${appt.doctorName} accepted your booking on ${appt.date} at ${appt.time}.',
            at: eventAt,
          ),
        );
      } else if (status == 'cancelled' || status == 'rejected') {
        alerts.add(
          _PatientAlert(
            icon: Icons.cancel,
            color: AppColors.error,
            title: 'Appointment Rejected',
            body:
                '${appt.doctorName} rejected/cancelled your booking for ${appt.date} at ${appt.time}.',
            at: eventAt,
          ),
        );
      } else {
        alerts.add(
          _PatientAlert(
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warning,
            title: 'Booking Pending',
            body:
                'Your booking request with ${appt.doctorName} is still pending.',
            at: eventAt,
          ),
        );
      }

      final appointmentAt = _parseAppointmentDateTime(appt);
      final isConfirmed = status == 'confirmed' || status == 'accepted';
      if (appointmentAt != null && isConfirmed) {
        final diff = appointmentAt.difference(now);
        if (!diff.isNegative && diff.inHours <= 24) {
          alerts.add(
            _PatientAlert(
              icon: Icons.alarm,
              color: AppColors.warning,
              title: 'Appointment Reminder',
              body:
                  'Upcoming with ${appt.doctorName} on ${appt.date} at ${appt.time}.',
              at: appointmentAt,
            ),
          );
        }
      }
    }

    alerts.sort((a, b) => b.at.compareTo(a.at));
    return alerts;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().userId;
    final db = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined, color: Colors.white),
            tooltip: 'My Appointments',
            onPressed: () => context.go('/appointments'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            tooltip: 'Messages',
            onPressed: () => context.go('/chat'),
          ),
        ],
        elevation: 0,
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Please log in to see alerts'))
          : StreamBuilder<List<AppointmentModel>>(
              stream: db.getUserAppointments(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load alerts\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final alerts = _buildAlerts(snapshot.data ?? const []);
                if (alerts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No alerts yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Book an appointment to receive updates here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.greyText),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/doctors/all'),
                            icon: const Icon(Icons.search),
                            label: const Text('Browse Doctors'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = alerts[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.go('/appointments'),
                      child: Container(
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: n.color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(n.icon, color: n.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.body,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.bodyText,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _timeAgo(n.at),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

class _PatientAlert {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final DateTime at;

  const _PatientAlert({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.at,
  });
}
