import 'package:intl/intl.dart';

class Formatters {
  static String currency(int cents, {String symbol = '\$'}) {
    final dollars = cents / 100;
    return '$symbol${dollars.toStringAsFixed(2)}';
  }

  static String distance(double meters, {bool imperial = true}) {
    if (imperial) {
      final miles = meters / 1609.34;
      if (miles < 0.1) {
        final feet = meters * 3.28084;
        return '${feet.round()} ft';
      }
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      if (meters < 1000) {
        return '${meters.round()} m';
      }
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  static String duration(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }

  static String time(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String date(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final inputDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (inputDate == today) {
      return 'Today';
    } else if (inputDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  static String dateTime(DateTime dateTime) {
    return '${date(dateTime)} at ${time(dateTime)}';
  }

  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return date(dateTime);
    }
  }

  static String phoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }
    return phone;
  }

  static String rating(double rating) {
    return rating.toStringAsFixed(1);
  }

  static String percentage(double value) {
    return '${(value * 100).round()}%';
  }
}
