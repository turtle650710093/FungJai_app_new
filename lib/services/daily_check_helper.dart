import 'package:shared_preferences/shared_preferences.dart';

class DailyCheckHelper {
  static const String _lastUsedKey = 'last_used_date';

  /// ตรวจสอบว่าวันนี้ใช้แอปแล้วหรือยัง
  static Future<bool> hasUsedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsed = prefs.getString(_lastUsedKey);
    
    if (lastUsed == null) return false;
    
    final lastDate = DateTime.parse(lastUsed);
    final today = DateTime.now();
    
    // เช็คว่าเป็นวันเดียวกันหรือไม่
    return lastDate.year == today.year &&
           lastDate.month == today.month &&
           lastDate.day == today.day;
  }

  /// บันทึกว่าใช้แอปวันนี้แล้ว
  static Future<void> markAsUsedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsedKey, DateTime.now().toIso8601String());
    print('✅ Marked as used today');
  }

  /// ล้างข้อมูล (สำหรับ testing)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUsedKey);
    print('🔄 Daily check reset');
  }
}