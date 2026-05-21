/// [AppointmentModel] typifies your schedule sessions, protecting the view from key typing errors.
class AppointmentModel {
  final int day;
  final int month;
  final int year;
  final String time;
  final String title;

  AppointmentModel({
    required this.day,
    required this.month,
    required this.year,
    required this.time,
    required this.title,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      day: map['day'] as int? ?? DateTime.now().day,
      month: map['month'] as int? ?? DateTime.now().month,
      year: map['year'] as int? ?? DateTime.now().year,
      time: map['time'] as String? ?? '00:00',
      title: map['title'] as String? ?? 'Sem Título',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'time': time,
      'title': title,
    };
  }
}