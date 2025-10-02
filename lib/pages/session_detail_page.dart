import 'package:flutter/material.dart';
import 'package:fungjai_app_new/services/emotion_database_helper.dart';

class SessionDetailPage extends StatefulWidget {
  final int sessionId;

  const SessionDetailPage({super.key, required this.sessionId});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  final EmotionDatabaseHelper _emotionDb = EmotionDatabaseHelper();
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final session = await _emotionDb.getSession(widget.sessionId);
    final records = await _emotionDb.getSessionRecords(widget.sessionId);
    final stats = await _emotionDb.getSessionStatistics(widget.sessionId);

    setState(() {
      _session = session;
      _records = records;
      _statistics = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบข้อมูล')),
        body: const Center(child: Text('ไม่พบ Session นี้')),
      );
    }

    final emotionCounts = _statistics?['emotion_counts'] as Map<String, int>? ?? {};
    final dominantEmotion = _statistics?['dominant_emotion'] as String? ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: Text('Session ${widget.sessionId}'),
        backgroundColor: const Color(0xFF1B7070),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _session!['question_set_title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('เริ่ม: ${_formatDateTime(_session!['start_time'])}'),
                    if (_session!['end_time'] != null)
                      Text('สิ้นสุด: ${_formatDateTime(_session!['end_time'])}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dominant Emotion
            Card(
              color: _getEmotionColor(dominantEmotion).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      _getEmotionEmoji(dominantEmotion),
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'อารมณ์โดยรวม',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            _getEmotionTextThai(dominantEmotion),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Emotion Distribution
            if (emotionCounts.isNotEmpty) ...[
              const Text(
                'การกระจายอารมณ์',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...emotionCounts.entries.map((entry) {
                final percentage = (_records.isNotEmpty)
                    ? (entry.value / _records.length * 100)
                    : 0.0;
                return _buildEmotionBar(
                  _getEmotionTextThai(entry.key),
                  entry.value,
                  percentage,
                  _getEmotionColor(entry.key),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],

            // Records List
            const Text(
              'รายละเอียดคำตอบทั้งหมด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._records.map((record) => _buildRecordCard(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBar(String emotion, int count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                emotion,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getEmotionColor(record['emotion']),
                  child: Text(
                    'Q${record['question_order']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record['question_text'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _getEmotionEmoji(record['emotion']),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  _getEmotionTextThai(record['emotion']),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(record['confidence'] * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year + 543} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} น.';
    } catch (e) {
      return isoString;
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry': return '😡';
      case 'frustrated': return '😤';
      case 'happy': return '😊';
      case 'neutral': return '😐';
      case 'sad': return '😢';
      default: return '🤔';
    }
  }

  String _getEmotionTextThai(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry': return 'โกรธ';
      case 'frustrated': return 'หงุดหงิด';
      case 'happy': return 'มีความสุข';
      case 'neutral': return 'เป็นกลาง';
      case 'sad': return 'เศร้า';
      default: return 'ไม่ทราบ';
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry': return Colors.red;
      case 'frustrated': return Colors.orange;
      case 'happy': return Colors.yellow;
      case 'neutral': return Colors.grey;
      case 'sad': return Colors.blue;
      default: return Colors.grey;
    }
  }
}