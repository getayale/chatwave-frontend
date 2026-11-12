class DateFormatter {
  static String formatMessageTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();

    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;

    final minute = localTime.minute.toString().padLeft(2, '0');

    final period = localTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
