import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fungjai_app_new/services/emotion_database_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final EmotionDatabaseHelper _emotionDb = EmotionDatabaseHelper();
  
  List<Map<String, dynamic>> _todaySessions = [];
  Map<String, int> _monthlyData = {};
  
  bool _isLoading = true;
  bool _localeInitialized = false;
  String _selectedView = 'daily';
  
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  /// ✅ Initialize Thai locale
  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('th_TH', null);
      setState(() {
        _localeInitialized = true;
      });
      _loadData();
    } catch (e) {
      print('Error initializing locale: $e');
      setState(() {
        _localeInitialized = true;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!_localeInitialized) return;
    
    setState(() => _isLoading = true);

    try {
      if (_selectedView == 'daily') {
        await _loadDailyData();
      } else {
        await _loadMonthlyData();
      }
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadDailyData() async {
    final db = await _emotionDb.database;
    
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      0, 0, 0,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23, 59, 59,
    );
    
    print('🔍 Loading sessions for ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');
    
    final sessions = await db.query(
      'sessions',
      where: 'status = ? AND completed_questions >= ? AND start_time >= ? AND start_time <= ?',
      whereArgs: [
        'completed',
        5,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
    );

    print('📊 Found ${sessions.length} completed sessions on ${_formatDateSafe(_selectedDate)}');

    List<Map<String, dynamic>> todaySessions = [];

    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final sessionId = session['id'] as int;
      
      final records = await _emotionDb.getSessionRecords(sessionId);
      
      if (records.isEmpty) continue;

      int positiveCount = records.where((r) {
        final emotion = (r['emotion'] as String?)?.toLowerCase();
        return emotion == 'happy' || emotion == 'neutral';
      }).length;

      double positiveRatio = positiveCount / records.length;
      
      todaySessions.add({
        'session_number': i + 1,
        'session_id': sessionId,
        'timestamp': session['start_time'] as String,
        'positive_ratio': positiveRatio,
        'total_questions': records.length,
        'positive_count': positiveCount,
      });
      
      print('  ✅ Session ${i + 1}: ${(positiveRatio * 100).toStringAsFixed(0)}% positive ($positiveCount/${records.length})');
    }

    setState(() {
      _todaySessions = todaySessions;
    });

    print('✅ Loaded ${_todaySessions.length} sessions for daily chart');
  }

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

  /// ✅ Safe date formatting
  String _formatDateSafe(DateTime date, [String pattern = 'd MMMM yyyy']) {
    try {
      if (_localeInitialized) {
        return DateFormat(pattern, 'th_TH').format(date);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeSafe(DateTime date) {
    try {
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  bool _canGoToNextDay() {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    final today = DateTime.now();
    return tomorrow.isBefore(DateTime(today.year, today.month, today.day, 23, 59, 59));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
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
      body: !_localeInitialized || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabSelector(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _selectedView == 'daily'
                        ? _buildDailyList()  // ✅ เปลี่ยนเป็นรายการ
                        : _buildMonthlyChart(),  // ✅ ยังคงเป็นกราฟวงกลม
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
              icon: Icons.list_alt_rounded,  // ✅ เปลี่ยน icon เป็นรายการ
              isSelected: _selectedView == 'daily',
              onTap: () {
                setState(() {
                  _selectedView = 'daily';
                  _selectedDate = DateTime.now();
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

  // ✅ หน้ารายวัน - แสดงเป็นรายการข้อความ (ไม่มีกราฟ)
  Widget _buildDailyList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 20),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'อารมณ์เชิงบวก คือ ผลรวมของอารมณ์มีความสุขและเป็นกลาง',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _todaySessions.isEmpty
              ? _buildEmptyState('ยังไม่มีข้อมูลในวันนี้')
              : _buildSessionsList(),
        ],
      ),
    );
  }

  // ✅ แสดงรายการชุดคำถาม (ไม่มีกราฟและไม่มีสถิติสรุป)
  Widget _buildSessionsList() {
    return Container(
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                Text(
                  'ทำทั้งหมด ${_todaySessions.length} ชุด',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          
          // List of sessions
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todaySessions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final session = _todaySessions[index];
              final sessionNumber = session['session_number'] as int;
              final timestamp = session['timestamp'] as String;
              final time = DateTime.parse(timestamp);
              final positiveRatio = session['positive_ratio'] as double;
              final positiveCount = session['positive_count'] as int;
              final totalQuestions = session['total_questions'] as int;
              final percentage = (positiveRatio * 100).toStringAsFixed(0);
              
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Session number badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2D5F5F),
                            const Color(0xFF2D5F5F).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ชุดที่',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '$sessionNumber',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Session details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeSafe(time),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'อารมณ์เชิงบวก $positiveCount จาก $totalQuestions คำถาม',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Percentage badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPercentageColor(positiveRatio).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getPercentageColor(positiveRatio).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getPercentageColor(positiveRatio),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper function to get color based on percentage
  Color _getPercentageColor(double ratio) {
    if (ratio >= 0.75) return const Color(0xFF4CAF50);
    if (ratio >= 0.50) return const Color(0xFF2196F3);
    if (ratio >= 0.25) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Widget _buildDateSelector() {
    final isToday = _isToday(_selectedDate);
    final canGoNext = _canGoToNextDay();
    
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
            color: const Color(0xFF2D5F5F),
          ),
          
          Expanded(
            child: Column(
              children: [
                Text(
                  isToday ? 'วันนี้' : _formatDateSafe(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F5F),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isToday)
                  Text(
                    _formatDateSafe(_selectedDate, 'EEEE'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? () => _changeDate(1) : null,
            color: canGoNext ? const Color(0xFF2D5F5F) : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  // ✅ หน้ารายเดือน - ยังคงมีกราฟวงกลมเหมือนเดิม
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
                  _formatDateSafe(_selectedMonth, 'MMMM yyyy'),
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
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _monthlyData.entries.map((entry) {
                        final percentage = (entry.value / total * 100);
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          color: colors[entry.key] ?? Colors.grey,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                ..._monthlyData.entries.map((entry) {
                  final percentage = (entry.value / total * 100);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors[entry.key] ?? Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} ครั้ง',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors[entry.key] ?? Colors.grey,
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
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}