import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/supabase_service.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../theme/app_theme.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _supabaseService
        .streamTasks(_supabaseService.supabase.auth.currentUser!.id)
        .listen((tasks) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _supabaseService.getTasks(
          _supabaseService.supabase.auth.currentUser!.id);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      final searchMatch = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return searchMatch;
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return b.assignedAt.compareTo(a.assignedAt);
        }
        return a.isCompleted ? 1 : -1;
      });
  }

  List<Task> get _pendingTasks => _filteredTasks.where((task) => !task.isCompleted).toList();
  List<Task> get _completedTasks => _filteredTasks.where((task) => task.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInLeft(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                'My Tasks',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            FadeInLeft(
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                '${_pendingTasks.length} tasks remaining',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        FadeInRight(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.oceanGradient.scale(0.3),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FadeInLeft(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.glassShadow,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search tasks...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredTasks.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No tasks available'
                            : 'No tasks found for "$_searchQuery"',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'All caught up! Take a break or start a new task.'
                            : 'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_pendingTasks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'In Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          duration: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: TaskCard(
                              task: _pendingTasks[index],
                              onComplete: () async {
                                await _supabaseService.markTaskComplete(_pendingTasks[index].id);
                              },
                            ),
                          ),
                        );
                      },
                      childCount: _pendingTasks.length,
                    ),
                  ),
                ),
              ],
              if (_completedTasks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          duration: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Opacity(
                              opacity: 0.7,
                              child: TaskCard(
                                task: _completedTasks[index],
                                onComplete: () async {
                                  await _supabaseService.markTaskComplete(_completedTasks[index].id);
                                },
                                useSecondaryColor: true,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _completedTasks.length,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Implement add task functionality
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}