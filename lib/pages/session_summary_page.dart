import 'package:flutter/material.dart';
import 'dart:math' as math;

class SessionSummaryPage extends StatelessWidget {
  final int sessionId;
  final Map<String, dynamic> statistics;

  const SessionSummaryPage({
    super.key,
    required this.sessionId,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final emotionCounts = statistics['emotion_counts'] as Map<String, int>? ?? {};
    final totalRecords = statistics['total_records'] as int? ?? 0;
    final avgConfidence = statistics['avg_confidence'] as double? ?? 0.0;
    final dominantEmotion = statistics['dominant_emotion'] as String? ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('สรุปผลการสนทนา'),
        backgroundColor: Colors.amber,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              const Text(
                'เสร็จสิ้นการสนทนา!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Summary Card
              _buildSummaryCard(
                'อารมณ์โดดเด่น',
                _getEmotionEmoji(dominantEmotion),
                _getEmotionTextThai(dominantEmotion),
              ),
              const SizedBox(height: 16),

              // Statistics
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildStatRow(
                        '💬 คำตอบทั้งหมด',
                        '$totalRecords คำตอบ',
                      ),
                      const Divider(height: 24),
                      _buildStatRow(
                        '🎯 ความมั่นใจเฉลี่ย',
                        '${(avgConfidence * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Emotion Breakdown
              if (emotionCounts.isNotEmpty) ...[
                const Text(
                  'การกระจายของอารมณ์',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...emotionCounts.entries.map((entry) {
                  final percentage = (entry.value / totalRecords * 100);
                  return _buildEmotionBar(
                    _getEmotionTextThai(entry.key),
                    entry.value,
                    percentage,
                    _getEmotionColor(entry.key),
                  );
                }).toList(),
              ],

              const SizedBox(height: 32),

              // Buttons
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('กลับหน้าหลัก'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String emoji, String emotion) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              emoji,
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 8),
            Text(
              emotion,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionBar(String emotion, int count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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