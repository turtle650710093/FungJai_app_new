import 'package:flutter/material.dart';
import 'package:fungjai_app_new/services/emotion_database_helper.dart';

class DebugDatabasePage extends StatefulWidget {
  const DebugDatabasePage({super.key});

  @override
  State<DebugDatabasePage> createState() => _DebugDatabasePageState();
}

class _DebugDatabasePageState extends State<DebugDatabasePage> {
  final EmotionDatabaseHelper _db = EmotionDatabaseHelper();
  List<Map<String, dynamic>> _records = [];
  Map<String, int> _emotionCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _db.getAllEmotionRecords();
    
    Map<String, int> counts = {};
    for (var record in records) {
      final emotion = record['emotion'] as String;
      counts[emotion] = (counts[emotion] ?? 0) + 1;
    }
    
    setState(() {
      _records = records;
      _emotionCounts = counts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - Database'),
        backgroundColor: const Color(0xFF2D5F5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // สถิติ
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สถิติอารมณ์',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text('ทั้งหมด: ${_records.length} records'),
                          const Divider(),
                          ..._emotionCounts.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${entry.key}:'),
                                  Text(
                                    '${entry.value} (${(entry.value / _records.length * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // รายการทั้งหมด
                  Text(
                    'Records ทั้งหมด',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  
                  ..._records.reversed.map((record) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(
                          '${record['emotion']} - ${(record['confidence'] * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Session: ${record['session_id']} | Q${record['question_order']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Question: ${record['question_text']}'),
                                const SizedBox(height: 8),
                                Text('Timestamp: ${record['timestamp']}'),
                                const Divider(),
                                Text('Scores:'),
                                Text('  Happy: ${record['happy_score']}'),
                                Text('  Sad: ${record['sad_score']}'),
                                Text('  Angry: ${record['angry_score']}'),
                                Text('  Neutral: ${record['neutral_score']}'),
                                Text('  Frustrated: ${record['frustrated_score']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}