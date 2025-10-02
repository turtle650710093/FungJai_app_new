import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/notification_settings_page.dart';
import 'package:fungjai_app_new/pages/history_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});  // ✅ เพิ่ม const ที่นี่

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF5F5DC),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1B7070),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'FungJai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'ดูแลจิตใจคุณทุกวัน',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // เมนู: แจ้งเตือนรายวัน
            ListTile(
              leading: const Icon(
                Icons.notifications_active,
                color: Color(0xFF1B7070),
                size: 28,
              ),
              title: const Text(
                'แจ้งเตือนรายวัน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'ตั้งค่าการแจ้งเตือนและเวลา',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),

            const Divider(height: 1, thickness: 1),

            // เมนู: ข้อมูลย้อนหลัง
            ListTile(
              leading: const Icon(
                Icons.history,
                color: Color(0xFF1B7070),
                size: 28,
              ),
              title: const Text(
                'ข้อมูลย้อนหลัง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                'ดูประวัติการบันทึกอารมณ์',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryPage(),
                  ),
                );
              },
            ),

            const Divider(height: 1, thickness: 1),

            const SizedBox(height: 16),

            // ปุ่มปิด Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('ปิดเมนู'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B7070),
                  side: const BorderSide(color: Color(0xFF1B7070)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}