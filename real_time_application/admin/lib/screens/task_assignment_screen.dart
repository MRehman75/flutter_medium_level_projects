import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({Key? key}) : super(key: key);

  @override
  _TaskAssignmentScreenState createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feedbackController = TextEditingController();
  String? _assignmentType = 'single';
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _tasks = [];
  List<String> _selectedStudents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _fetchTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, name, email')
          .eq('role', 'student')
          .order('name');
      
      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching students: $e')),
        );
      }
    }
  }

  Future<void> _fetchTasks() async {
    try {
      print('Fetching tasks...');
      final response = await supabase
          .from('tasks')
          .select('''
            id,
            student_id,
            title,
            description,
            status,
            student:users!tasks_student_id_fkey (
              id,
              name,
              email
            )
          ''');
      
      print('Tasks fetched: ${response.length}');
      
      if (mounted) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tasks: $e')),
        );
      }
    }
  }

  Future<void> _assignTask() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_assignmentType == 'single' && _selectedStudents.length != 1) {
        throw 'Please select one student for single assignment';
      }
      if (_assignmentType == 'multiple' && _selectedStudents.isEmpty) {
        throw 'Please select at least one student for multiple assignment';
      }

      final studentIds = _assignmentType == 'all' 
          ? _students.map((s) => s['id'] as String).toList() 
          : _selectedStudents;

      for (var studentId in studentIds) {
        try {
          final taskData = {
            'student_id': studentId,
            'title': _titleController.text,
            'description': _descriptionController.text,
            'status': 'pending'
          };
          
          final response = await supabase
              .from('tasks')
              .insert(taskData)
              .select()
              .single();
          
          print('Task assigned successfully: ${response['id']}');
        } catch (e) {
          print('Error assigning task to student $studentId: $e');
          if (e.toString().contains('foreign key constraint')) {
            throw 'Failed to assign task. Please make sure the student exists.';
          }
          throw 'Failed to assign task. Please try again.';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully')),
        );
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedStudents = [];
          _assignmentType = 'single';
        });
        await _fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      await supabase
          .from('tasks')
          .update({'status': status})
          .eq('id', taskId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task status updated')),
        );
        await _fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _addFeedback(String taskId) async {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback')),
      );
      return;
    }

    try {
      await supabase.from('tasks').update({
        'feedback': _feedbackController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback added successfully')),
        );
        _feedbackController.clear();
        await _fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showFeedbackDialog(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Add Feedback', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _feedbackController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Feedback',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              _addFeedback(taskId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
                    Text(
                      'Task Assignment',
                      style: const TextStyle(
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
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
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
                            Text(
                              'New Task',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate()
                              .fadeIn(duration: 500.ms)
                              .slideX(begin: -0.2),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Task Title',
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF64B5F6)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF64B5F6)),
                                ),
                                labelStyle: const TextStyle(color: Colors.white70),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ).animate()
                              .fadeIn(duration: 500.ms, delay: 200.ms)
                              .slideX(begin: -0.2),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF64B5F6)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF64B5F6)),
                                ),
                                labelStyle: const TextStyle(color: Colors.white70),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ).animate()
                              .fadeIn(duration: 500.ms, delay: 400.ms)
                              .slideX(begin: -0.2),
                            const SizedBox(height: 24),
                            Text(
                              'Assignment Type',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildAssignmentTypeButton('Single', 'single'),
                                const SizedBox(width: 8),
                                _buildAssignmentTypeButton('Multiple', 'multiple'),
                                const SizedBox(width: 8),
                                _buildAssignmentTypeButton('All', 'all'),
                              ],
                            ),
                            if (_assignmentType != 'all') ...[
                              const SizedBox(height: 24),
                              Text(
                                'Select Students',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                height: 200,
                                child: ListView.builder(
                                  itemCount: _students.length,
                                  itemBuilder: (context, index) {
                                    final student = _students[index];
                                    final isSelected = _selectedStudents.contains(student['id']);
                                    return ListTile(
                                      title: Text(
                                        student['name'],
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        student['email'],
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF64B5F6),
                                        child: Text(
                                          student['name'][0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      trailing: Icon(
                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                        color: isSelected ? const Color(0xFF64B5F6) : Colors.white54,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedStudents.remove(student['id']);
                                          } else {
                                            if (_assignmentType == 'single') {
                                              _selectedStudents = [student['id']];
                                            } else {
                                              _selectedStudents.add(student['id']);
                                            }
                                          }
                                        });
                                      },
                                    ).animate()
                                      .fadeIn(duration: 500.ms, delay: Duration(milliseconds: 100 * index))
                                      .slideX(begin: -0.2);
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _assignTask,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF64B5F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Assign Task',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ).animate()
                              .scale(duration: 500.ms, delay: 600.ms)
                              .then()
                              .shimmer(duration: 1200.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Assigned Tasks',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Color(0xFF64B5F6),
                                offset: Offset(1, 1),
                                blurRadius: 2
                              ),
                            ],
                          ),
                        ).animate()
                          .fadeIn(duration: 500.ms)
                          .slideX(begin: -0.2),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _fetchTasks,
                        ).animate()
                          .scale(duration: 600.ms)
                          .then()
                          .shimmer(duration: 1200.ms),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_tasks.isEmpty)
                      Center(
                        child: Text(
                          'No tasks assigned yet',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            final student = task['student'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: ListTile(
                                title: Text(
                                  task['title'] ?? 'Untitled Task',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (student != null) Text(
                                      'Assigned to: ${student['name']}',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: task['status'] == 'completed'
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Status: ${task['status']}',
                                        style: TextStyle(
                                          color: task['status'] == 'completed'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                    if (task['feedback'] != null)
                                      Text(
                                        'Feedback: ${task['feedback']}',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.feedback, color: Color(0xFF64B5F6)),
                                      onPressed: () => _showFeedbackDialog(task['id']),
                                    ).animate()
                                      .scale(duration: 300.ms)
                                      .then()
                                      .shimmer(duration: 1200.ms),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                                      color: const Color(0xFF1E1E2E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'pending',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.pending, color: Colors.orange),
                                              const SizedBox(width: 8),
                                              const Text('Mark as Pending',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'completed',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.green),
                                              const SizedBox(width: 8),
                                              const Text('Mark as Completed',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (status) => _updateTaskStatus(task['id'], status),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate()
                              .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 50))
                              .slideX(begin: 0.2);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentTypeButton(String label, String value) {
    final isSelected = _assignmentType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _assignmentType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF64B5F6) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF64B5F6) : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    ).animate()
      .scale(duration: 300.ms)
      .then()
      .shimmer(duration: 1200.ms);
  }
}