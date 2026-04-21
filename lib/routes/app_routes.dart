import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/appointment/appointment_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/doctors/doctor_bookings_screen.dart';
import '../screens/doctors/doctor_dashboard_screen.dart';
import '../screens/doctors/doctor_description_screen.dart';
import '../screens/doctors/doctor_list_screen.dart';
import '../screens/doctors/doctor_profile_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/notification/chat_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/help_center_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../screens/profile/password_manager_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final role = (user?.userMetadata?['role'] ?? 'patient').toString().toLowerCase();
      final isDoctor = role == 'doctor';

      final publicRoutes = ['/', '/welcome', '/login', '/signup'];
      final isPublicRoute = publicRoutes.contains(location);
      final isDoctorRoute = location.startsWith('/doctor/');

      if (!isLoggedIn && !isPublicRoute) return '/welcome';

      if (isLoggedIn && isPublicRoute && location != '/') {
        return isDoctor ? '/doctor/home' : '/home';
      }

      if (isLoggedIn && isDoctor && !isDoctorRoute && location != '/profile/password') {
        return '/doctor/home';
      }

      if (isLoggedIn && !isDoctor && isDoctorRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/doctors/:gender',
        builder: (_, state) => DoctorListScreen(gender: state.pathParameters['gender'] ?? 'all'),
      ),
      GoRoute(path: '/doctor/home', builder: (_, __) => const DoctorDashboardScreen()),
      GoRoute(path: '/doctor/bookings', builder: (_, __) => const DoctorBookingsScreen()),
      GoRoute(path: '/doctor/profile', builder: (_, __) => const DoctorProfileScreen()),
      GoRoute(
        path: '/doctor/:id',
        builder: (_, state) => DoctorDescriptionScreen(doctorId: state.pathParameters['id'] ?? ''),
      ),

      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/notification', builder: (_, __) => const NotificationScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/profile/password', builder: (_, __) => const PasswordManagerScreen()),
      GoRoute(path: '/profile/notification-settings', builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: '/profile/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/profile/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: '/profile/help', builder: (_, __) => const HelpCenterScreen()),

      GoRoute(
        path: '/schedule',
        builder: (_, state) => ScheduleScreen(
          doctorId: state.uri.queryParameters['doctorId'],
          doctorName: state.uri.queryParameters['doctorName'] != null
              ? Uri.decodeComponent(state.uri.queryParameters['doctorName']!)
              : null,
        ),
      ),
      GoRoute(path: '/appointments', builder: (_, __) => const AppointmentScreen()),
      GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
    ],
  );
}
