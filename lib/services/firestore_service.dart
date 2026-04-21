import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';

class FirestoreService {
  final SupabaseClient _db = Supabase.instance.client;

  Stream<List<DoctorModel>> getDoctors() {
    return _db.from('doctors').stream(primaryKey: ['id']).map(
          (rows) => rows
              .map(
                (row) => DoctorModel.fromMap(
                  Map<String, dynamic>.from(row),
                  row['id'].toString(),
                ),
              )
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _db
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((row) => AppointmentModel.fromMap(
                  Map<String, dynamic>.from(row),
                  row['id'].toString(),
                ))
            .toList());
  }

  Stream<List<DoctorModel>> getDoctorsByGender(String gender) {
    return _db
        .from('doctors')
        .stream(primaryKey: ['id'])
        .eq('gender', gender)
        .map(
          (rows) => rows
              .map(
                (row) => DoctorModel.fromMap(
                  Map<String, dynamic>.from(row),
                  row['id'].toString(),
                ),
              )
              .toList(),
        );
  }

  Future<DoctorModel?> getDoctor(String id) async {
    final row = await _db.from('doctors').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return DoctorModel.fromMap(Map<String, dynamic>.from(row), id);
  }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    await _db.from('appointments').insert(appointment.toMap());
  }

  Stream<List<AppointmentModel>> getUserAppointments(String userId) {
    return _db
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((row) => AppointmentModel.fromMap(
                  Map<String, dynamic>.from(row),
                  row['id'].toString(),
                ))
            .toList());
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _db
        .from('appointments')
        .update({'status': 'cancelled'}).eq('id', appointmentId);
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    await _db.from('appointments').update({'status': status}).eq('id', appointmentId);
  }
}
