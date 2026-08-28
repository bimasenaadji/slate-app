import 'package:intl/intl.dart';

class DateHelper {
  // Determines dynamic greeting based on current system hour (Pagi, Siang, Sore, Malam)
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Sore,';
    } else {
      return 'Malam,';
    }
  }

  // Formats system date to Indonesian e.g., "Selasa, 25 Agustus"
  static String formatTodayDate() {
    try {
      return DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now());
    } catch (e) {
      return DateFormat('EEEE, d MMMM').format(DateTime.now());
    }
  }
}
