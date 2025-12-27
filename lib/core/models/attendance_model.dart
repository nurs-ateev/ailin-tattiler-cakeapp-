import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String workerId;
  final String workerName;
  final DateTime date;
  final bool isPresent; // true = пришёл, false = не пришёл
  final DateTime? checkInTime; // Время прихода
  final DateTime? checkOutTime; // Время ухода
  final double? hoursWorked; // Отработано часов
  final double? salary; // Зарплата за день
  final String? notes; // Примечания (опционально)

  Attendance({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.isPresent,
    this.checkInTime,
    this.checkOutTime,
    this.hoursWorked,
    this.salary,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
      'checkInTime': checkInTime != null
          ? Timestamp.fromDate(checkInTime!)
          : null,
      'checkOutTime': checkOutTime != null
          ? Timestamp.fromDate(checkOutTime!)
          : null,
      'hoursWorked': hoursWorked,
      'salary': salary,
      'notes': notes,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map, String documentId) {
    return Attendance(
      id: documentId,
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPresent: map['isPresent'] ?? false,
      checkInTime: (map['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (map['checkOutTime'] as Timestamp?)?.toDate(),
      hoursWorked: map['hoursWorked']?.toDouble(),
      salary: map['salary']?.toDouble(),
      notes: map['notes'],
    );
  }
}
