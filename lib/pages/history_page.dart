import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fungjai_app_new/services/emotion_database_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final EmotionDatabaseHelper _emotionDb = EmotionDatabaseHelper();
  List<Map<String, dynamic>> _dailyData = [];
  Map<String, int> _monthlyData = {};
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  String _selectedView = 'daily'; // 'daily' หรือ 'monthly'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (_selectedView == 'daily') {
      await _loadDailyData();
    } else {
      await _loadMonthlyData();
    }

    setState(() => _isLoading = false);
  }

  /// ✅ แก้ไข: ดึงเฉพาะ session ที่ทำครบ (status = 'completed' และ completed_questions >= 5)
  Future<void> _loadDailyData() async {
    final db = await _emotionDb.database;
    
    // ดึง sessions ที่ status = 'completed' และทำครบ 5 คำถาม
    final sessions = await db.query(
      'sessions',
      where: 'status = ? AND completed_questions >= ?',
      whereArgs: ['completed', 5],
      orderBy: 'start_time DESC',
      limit: 10,
    );

    print('📊 Found ${sessions.length} completed sessions (5+ questions)');

    List<Map<String, dynamic>> dailyData = [];

    for (var session in sessions) {
      final sessionId = session['id'] as int;
      
      // ดึง emotion records ของ session นี้
      final records = await _emotionDb.getSessionRecords(sessionId);
      
      if (records.isEmpty) continue;

      // นับอารมณ์เชิงบวก (happy, neutral)
      int positiveCount = records.where((r) {
        final emotion = (r['emotion'] as String?)?.toLowerCase();
        return emotion == 'happy' || emotion == 'neutral';
      }).length;

      double positiveRatio = positiveCount / records.length;
      
      dailyData.add({
        'session_id': sessionId,
        'timestamp': session['start_time'] as String,
        'positive_ratio': positiveRatio,
        'total_questions': records.length,
      });
    }

    setState(() {
      _dailyData = dailyData;
    });

    print('✅ Loaded ${_dailyData.length} completed sessions for daily chart');
  }

  /// ✅ ไม่ต้องแก้: รายเดือนใช้ทุก record (ถูกต้องอยู่แล้ว)
  Future<void> _loadMonthlyData() async {
    final records = await _emotionDb.getRecordsByMonth(_selectedMonth);
    Map<String, int> emotionCounts = {};
    
    for (var record in records) {
      final emotion = record['emotion'] as String?;
      if (emotion != null && emotion.isNotEmpty) {
        final translated = _translateEmotion(emotion);
        emotionCounts[translated] = (emotionCounts[translated] ?? 0) + 1;
      }
    }

    setState(() {
      _monthlyData = emotionCounts;
    });
  }

  String _translateEmotion(String emotion) {
    const map = {
      'happy': 'มีความสุข',
      'sad': 'เศร้า',
      'angry': 'โกรธ',
      'neutral': 'เป็นกลาง',
      'frustrated': 'หงุดหงิด',
    };
    return map[emotion.toLowerCase()] ?? emotion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D5F5F),
        title: const Text(
          'ประวัติ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Selector
                _buildTabSelector(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: _selectedView == 'daily'
                        ? _buildDailyChart()
                        : _buildMonthlyChart(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'รายวัน',
              icon: Icons.show_chart_rounded,
              isSelected: _selectedView == 'daily',
              onTap: () {
                setState(() {
                  _selectedView = 'daily';
                });
                _loadData();
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'รายเดือน',
              icon: Icons.pie_chart_rounded,
              isSelected: _selectedView == 'monthly',
              onTap: () {
                setState(() {
                  _selectedView = 'monthly';
                });
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5F5F) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    if (_dailyData.isEmpty) {
      return _buildEmptyState('ยังไม่มีข้อมูลชุดคำถามที่ทำครบ');
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สัดส่วนอารมณ์เชิงบวก',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5F5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'จากชุดคำถามที่ทำครบ (5 คำถาม)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 0.25,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${(value * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _dailyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${_dailyData.length - value.toInt()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['positive_ratio'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFF4CAF50),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF4CAF50),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.3),
                            const Color(0xFF4CAF50).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_monthlyData.isEmpty) {
      return _buildEmptyState('ยังไม่มีข้อมูลในเดือนนี้');
    }

    final total = _monthlyData.values.reduce((a, b) => a + b);
    final colors = {
      'มีความสุข': const Color(0xFF4CAF50),
      'เป็นกลาง': const Color(0xFF2196F3),
      'เศร้า': const Color(0xFFFF9800),
      'โกรธ': const Color(0xFFF44336),
      'หงุดหงิด': const Color(0xFFFF5722),
    };

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    });
                    _loadMonthlyData();
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F5F),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final now = DateTime.now();
                    if (_selectedMonth.isBefore(DateTime(now.year, now.month))) {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                      _loadMonthlyData();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Summary Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D5F5F).withOpacity(0.1),
                  const Color(0xFF2D5F5F).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assessment,
                  color: Color(0xFF2D5F5F),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'บันทึกทั้งหมด $total ครั้ง',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F5F),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pie Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 70,
                  sections: _monthlyData.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '',
                      color: colors[entry.key] ?? Colors.grey,
                      radius: 60,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รายละเอียด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F5F),
                  ),
                ),
                const SizedBox(height: 16),
                ..._monthlyData.entries.map((entry) {
                  final percent = (entry.value / total * 100);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors[entry.key] ?? Colors.grey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.value} ครั้ง (${percent.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5F5F),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}