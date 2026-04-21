class DoctorModel {
  final String id;
  final String? userId;
  final String name;
  final String specialty;
  final String designation;
  final String licenseNumber;
  final String gender;
  final int age;
  final String imageUrl;
  final String about;
  final double rating;
  final int experience;
  final List<String> availableDays;

  const DoctorModel({
    required this.id,
    this.userId,
    required this.name,
    required this.specialty,
    this.designation = '',
    this.licenseNumber = '',
    required this.gender,
    this.age = 0,
    required this.imageUrl,
    required this.about,
    required this.rating,
    required this.experience,
    required this.availableDays,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map, String id) {
    return DoctorModel(
      id: id,
      userId: map['user_id']?.toString(),
      name: map['name']?.toString() ?? '',
      specialty: map['specialty']?.toString() ?? '',
      designation: map['designation']?.toString() ?? '',
      licenseNumber: map['license_number']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'male',
      age: (map['age'] ?? 0).toInt(),
      imageUrl: (map['imageUrl'] ?? map['image_url'] ?? '').toString(),
      about: map['about']?.toString() ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      experience: (map['experience'] ?? 0).toInt(),
      availableDays: List<String>.from(map['availableDays'] ?? map['available_days'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'specialty': specialty,
        'designation': designation,
        'license_number': licenseNumber,
        'gender': gender,
        'age': age,
        'image_url': imageUrl,
        'about': about,
        'rating': rating,
        'experience': experience,
        'available_days': availableDays,
      };
}
