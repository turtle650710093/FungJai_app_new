import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Map<String, double> results;

  const ResultPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // หาอารมณ์ที่มีคะแนนสูงสุด
    final topEmotion = results.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผลการวิเคราะห์'),
        automaticallyImplyLeading: false, // เอาปุ่ม back ออก
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'อารมณ์หลักของคุณตอนนี้คือ:',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              topEmotion.key, // แสดงชื่ออารมณ์
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue, // อาจจะเปลี่ยนสีตามอารมณ์
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(topEmotion.value * 100).toStringAsFixed(1)}%', // แสดง %
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'รายละเอียดอารมณ์ทั้งหมด:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final entry = results.entries.elementAt(index);
                  return Card(
                    child: ListTile(
                      title: Text(entry.key),
                      trailing: Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                      subtitle: LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('กลับสู่หน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }
}