import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart'; // Added this import to fix the error

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final supabase = Supabase.instance.client;
  int _pendingCount = 0;
  int _completedCount = 0;
  List<Map<String, dynamic>> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view progress')),
        );
        return;
      }

      final response = await supabase
          .from('task_history')
          .select('id, task_id, status, tasks!inner(title, description)')
          .eq('student_id', userId);

      int pending = 0;
      int completed = 0;
      List<Map<String, dynamic>> completedTasks = [];

      for (var task in response) {
        if (task['status'] == 'pending') {
          pending++;
        } else if (task['status'] == 'completed') {
          completed++;
          completedTasks.add(task);
        }
      }

      setState(() {
        _pendingCount = pending;
        _completedCount = completed;
        _completedTasks = completedTasks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching progress: $e')),
      );
    }
  }

  Future<void> _submitFeedback(String taskId, String feedback) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('task_feedback').insert({
        'id': const Uuid().v4(), // Now this will work with the import
        'task_id': taskId,
        'student_id': userId,
        'feedback': feedback,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

  void _showFeedbackDialog(String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        String feedback = '';
        return AlertDialog(
          title: const Text('Submit Feedback'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Your Feedback'),
            maxLines: 3,
            onChanged: (value) => feedback = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (feedback.trim().isNotEmpty) {
                  _submitFeedback(taskId, feedback);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF97316),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFF97316),
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Pending Tasks', _pendingCount, const Color(0xFFF97316)),
                _buildStatCard('Completed Tasks', _completedCount, const Color(0xFF38BDF8)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Completed Tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            const SizedBox(height: 8),
            Expanded(
              child: _completedTasks.isEmpty
                  ? const Center(child: Text('No completed tasks yet.'))
                  : ListView.builder(
                itemCount: _completedTasks.length,
                itemBuilder: (context, index) {
                  final task = _completedTasks[index];
                  return Card(
                    child: ListTile(
                      title: Text(task['tasks']['title'] ?? 'Untitled Task'),
                      subtitle: Text(task['tasks']['description'] ?? 'No description'),
                      trailing: IconButton(
                        icon: const Icon(Icons.feedback, color: Color(0xFF38BDF8)),
                        onPressed: () => _showFeedbackDialog(task['task_id']),
                      ),
                    ),
                  ).animate().fadeIn(
                    duration: 500.ms,
                    delay: Duration(milliseconds: index * 100),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}