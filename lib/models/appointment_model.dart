class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String doctorName;
  final String date;
  final String time;
  final String status;
  final DateTime? createdAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
    this.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    final createdRaw = map['created_at'] ?? map['createdAt'];
    return AppointmentModel(
      id: id,
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      doctorId: (map['doctor_id'] ?? map['doctorId'] ?? '').toString(),
      doctorName: (map['doctor_name'] ?? map['doctorName'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      time: (map['time'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw.toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'date': date,
        'time': time,
        'status': status,
      };
}
