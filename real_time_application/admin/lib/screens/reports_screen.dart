import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _topPerformers = [];
  List<Map<String, dynamic>> _taskProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch all tasks with student information
      final response = await supabase
          .from('tasks')
          .select('''
            id,
            student_id,
            title,
            description,
            status,
            users!tasks_student_id_fkey (
              id,
              name,
              email
            )
          ''')
          .order('id');

      final List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(response);

      // Process tasks to get top performers
      final performerStats = <String, Map<String, dynamic>>{};
      for (final task in tasks) {
        if (task['status'] == 'completed' && task['users'] != null) {
          final name = task['users']['name'] as String;
          if (!performerStats.containsKey(name)) {
            performerStats[name] = {
              'name': name,
              'completed_tasks': 0,
            };
          }
          performerStats[name]!['completed_tasks'] = (performerStats[name]!['completed_tasks'] as int) + 1;
        }
      }

      // Process tasks data for timeline - group by every 5 tasks
      final List<Map<String, dynamic>> taskGroups = [];
      
      for (var i = 0; i < tasks.length; i += 5) {
        final end = (i + 5 < tasks.length) ? i + 5 : tasks.length;
        final group = tasks.sublist(i, end);
        final completed = group.where((task) => task['status'] == 'completed').length;
        final total = group.length;
        
        taskGroups.add({
          'date': 'Group ${(i ~/ 5) + 1}',
          'progress': total == 0 ? 0.0 : (completed / total * 100),
        });
      }

      if (mounted) {
        setState(() {
          _topPerformers = performerStats.values.toList()
            ..sort((a, b) => (b['completed_tasks'] as int).compareTo(a['completed_tasks'] as int));
          
          _taskProgress = taskGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Performance Reports',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Color(0xFF64B5F6),
                            offset: Offset(2, 2),
                            blurRadius: 4
                          ),
                        ],
                      ),
                    ).animate()
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchData,
                    ).animate()
                      .scale(duration: 600.ms)
                      .then()
                      .shimmer(duration: 1200.ms),
                  ],
                ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: const Color(0xFF64B5F6),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF64B5F6).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber)
                                      .animate()
                                      .scale(duration: 600.ms)
                                      .then()
                                      .shimmer(duration: 1200.ms),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Top Performers',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).animate()
                                      .fadeIn(duration: 500.ms)
                                      .slideX(begin: -0.2),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _topPerformers.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No data available',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                        )
                                      : BarChart(
                                          BarChartData(
                                            alignment: BarChartAlignment.spaceAround,
                                            maxY: (_topPerformers.first['completed_tasks'] as int).toDouble() * 1.2,
                                            gridData: FlGridData(show: false),
                                            borderData: FlBorderData(show: false),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    if (value >= _topPerformers.length) return const Text('');
                                                    return Text(
                                                      _topPerformers[value.toInt()]['name'].toString().split(' ')[0],
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              rightTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                              topTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                            ),
                                            barGroups: _topPerformers
                                                .take(5)
                                                .toList()
                                                .asMap()
                                                .entries
                                                .map((entry) => BarChartGroupData(
                                                  x: entry.key,
                                                  barRods: [
                                                    BarChartRodData(
                                                      toY: (entry.value['completed_tasks'] as int).toDouble(),
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                      ),
                                                      width: 20,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ],
                                                ))
                                                .toList(),
                                          ),
                                        ).animate()
                                          .scale(duration: 800.ms)
                                          .fadeIn(duration: 800.ms),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF64B5F6).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timeline, color: Color(0xFF64B5F6))
                                      .animate()
                                      .scale(duration: 600.ms)
                                      .then()
                                      .shimmer(duration: 1200.ms),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Task Progress Timeline',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).animate()
                                      .fadeIn(duration: 500.ms)
                                      .slideX(begin: -0.2),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _taskProgress.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No data available',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                        )
                                      : LineChart(
                                          LineChartData(
                                            gridData: FlGridData(
                                              show: true,
                                              drawVerticalLine: false,
                                              getDrawingHorizontalLine: (value) => FlLine(
                                                color: Colors.white.withOpacity(0.1),
                                                strokeWidth: 1,
                                              ),
                                            ),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      '${value.toInt()}%',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    if (value >= _taskProgress.length) return const Text('');
                                                    return Text(
                                                      _taskProgress[value.toInt()]['date'],
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              rightTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                              topTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                            ),
                                            borderData: FlBorderData(show: false),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: _taskProgress
                                                    .asMap()
                                                    .entries
                                                    .map((entry) => FlSpot(
                                                          entry.key.toDouble(),
                                                          entry.value['progress'],
                                                        ))
                                                    .toList(),
                                                isCurved: true,
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                                ),
                                                barWidth: 3,
                                                isStrokeCapRound: true,
                                                dotData: FlDotData(
                                                  show: true,
                                                  getDotPainter: (spot, percent, barData, index) =>
                                                      FlDotCirclePainter(
                                                        radius: 6,
                                                        color: const Color(0xFF7C3AED),
                                                        strokeWidth: 2,
                                                        strokeColor: Colors.white,
                                                      ),
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: true,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(0xFF4F46E5).withOpacity(0.3),
                                                      const Color(0xFF7C3AED).withOpacity(0.0),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).animate()
                                          .scale(duration: 800.ms)
                                          .fadeIn(duration: 800.ms),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}