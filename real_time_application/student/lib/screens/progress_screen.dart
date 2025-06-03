import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../services/supabase_service.dart';
import '../models/task.dart';
import '../widgets/streak_widget.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  int _completedTasks = 0;
  int _pendingTasks = 0;
  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _supabaseService.getTasks(
          _supabaseService.supabase.auth.currentUser!.id);
      final completed = tasks.where((task) => task.status == 'completed').length;
      final pending = tasks.where((task) => task.status == 'pending').length;

      int streak = 0;
      final completedTasks = tasks
          .where((task) => task.status == 'completed' && task.completedAt != null)
          .toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
      DateTime? lastDate;
      for (var task in completedTasks) {
        final completedDate = task.completedAt!.toLocal();
        final day = DateTime(completedDate.year, completedDate.month, completedDate.day);
        if (lastDate == null ||
            day.difference(lastDate).inDays == 1 ||
            day.difference(lastDate).inDays == 0) {
          streak++;
        } else {
          break;
        }
        lastDate = day;
      }

      setState(() {
        _completedTasks = completed;
        _pendingTasks = pending;
        _streak = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading progress: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProgress,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _isLoading
            ? SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressHeader(),
                    const SizedBox(height: 30),
                    _buildProgressCards(),
                    const SizedBox(height: 30),
                    _buildPieChart(),
                    const SizedBox(height: 40),
                    _buildStreakSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.oceanGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.glassShadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Keep up the great work!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCards() {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Row(
        children: [
          Expanded(
            child: _buildProgressCard(
              'Completed',
              _completedTasks,
              Icons.check_circle_outline,
              AppTheme.forestGradient,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildProgressCard(
              'Pending',
              _pendingTasks,
              Icons.pending_outlined,
              AppTheme.sunsetGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, int value, IconData icon, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.glassShadow,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return FadeInRight(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.lavenderGradient.scale(0.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.glassShadow,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _completedTasks.toDouble(),
                      color: AppTheme.quaternaryColor,
                      title: '${((_completedTasks / (_completedTasks + _pendingTasks)) * 100).round()}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: _pendingTasks.toDouble(),
                      color: AppTheme.tertiaryColor,
                      title: '${((_pendingTasks / (_completedTasks + _pendingTasks)) * 100).round()}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Completed', AppTheme.quaternaryColor),
                const SizedBox(width: 20),
                _buildLegendItem('Pending', AppTheme.tertiaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.sunsetGradient.scale(0.3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.glassShadow,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Streak',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            StreakWidget(streak: _streak),
          ],
        ),
      ),
    );
  }
}