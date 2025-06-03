import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/user.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<AppUser?> getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      return AppUser.fromJson(response);
    }
    return null;
  }

  Future<List<Task>> getTasks(String studentId) async {
    final response = await supabase
        .from('tasks')
        .select()
        .eq('student_id', studentId);
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<void> markTaskComplete(String taskId) async {
    await supabase
        .from('tasks')
        .update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    })
        .eq('id', taskId);
  }

  Stream<List<Task>> streamTasks(String studentId) {
    return supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .map((data) => data.map((json) => Task.fromJson(json)).toList());
  }
}