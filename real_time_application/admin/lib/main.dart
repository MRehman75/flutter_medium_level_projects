import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/login_screen.dart';
import 'screens/student_management_screen.dart';
import 'screens/task_assignment_screen.dart';
import 'screens/reports_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://xtagdwlgejapeneiwdex.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0YWdkd2xnZWphcGVuZWl3ZGV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjYxMzgsImV4cCI6MjA2MzE0MjEzOH0.8maRnW1sIRhg3f_gmtH_3Ei98-UbLs0om_klzId--o4',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
      theme: appTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/student_management': (context) => const StudentManagementScreen(),
        '/task_assignment': (context) => const TaskAssignmentScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  int totalStudents = 0;
  int totalTasks = 0;
  int completedTasks = 0;
  int pendingTasks = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final students = await supabase.from('users').select().eq('role', 'student');
      final tasks = await supabase.from('tasks').select();
      setState(() {
        totalStudents = students.length;
        totalTasks = tasks.length;
        completedTasks = tasks.where((task) => task['status'] == 'completed').length;
        pendingTasks = tasks.where((task) => task['status'] == 'pending').length;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching stats: $e')),
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
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: -0.2),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1) {
              _showQuickAccessDialog();
            }
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.white54,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Quick Access',
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Quick Action',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildQuickAccessOption(
                  'Student Management',
                  Icons.people,
                  const Color(0xFF64B5F6),
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/student_management');
                  },
                ),
                const SizedBox(height: 16),
                _buildQuickAccessOption(
                  'Task Assignment',
                  Icons.assignment,
                  const Color(0xFF81C784),
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/task_assignment');
                  },
                ),
                const SizedBox(height: 16),
                _buildQuickAccessOption(
                  'Reports',
                  Icons.analytics,
                  const Color(0xFFFFA726),
                  () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    ).animate()
      .scale(duration: 300.ms)
      .then()
      .shimmer(duration: 1200.ms);
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, 
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Admin Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildMenuButton(context),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people,
                label: 'Students',
                value: totalStudents.toString(),
                color: const Color(0xFF64B5F6),
              ),
              _buildStatItem(
                icon: Icons.task,
                label: 'Total Tasks',
                value: totalTasks.toString(),
                color: const Color(0xFF81C784),
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Completed',
                value: completedTasks.toString(),
                color: const Color(0xFF4CAF50),
              ),
              _buildStatItem(
                icon: Icons.pending,
                label: 'Pending',
                value: pendingTasks.toString(),
                color: const Color(0xFFFFA726),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms).then().shimmer(duration: 1200.ms);
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        child: const Icon(
          Icons.menu,
          color: Colors.white,
        ),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E2E),
      itemBuilder: (context) => [
        _buildMenuItem(
          'Add Student',
          Icons.person_add,
          '/student_management',
          const Color(0xFF4F46E5),
        ),
        _buildMenuItem(
          'Assign Tasks',
          Icons.assignment_add,
          '/task_assignment',
          const Color(0xFFDB2777),
        ),
        _buildMenuItem(
          'View Reports',
          Icons.analytics,
          '/reports',
          const Color(0xFF0D9488),
        ),
      ],
      onSelected: (value) => Navigator.pushNamed(context, value),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String text,
    IconData icon,
    String route,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: route,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildQuickActionCard(
          title: 'Student Management',
          icon: Icons.people,
          color: const Color(0xFF64B5F6),
          onTap: () => Navigator.pushNamed(context, '/student_management'),
        ),
        _buildQuickActionCard(
          title: 'Task Assignment',
          icon: Icons.assignment,
          color: const Color(0xFF81C784),
          onTap: () => Navigator.pushNamed(context, '/task_assignment'),
        ),
        _buildQuickActionCard(
          title: 'Reports',
          icon: Icons.bar_chart,
          color: const Color(0xFFFFA726),
          onTap: () => Navigator.pushNamed(context, '/reports'),
        ),
        _buildQuickActionCard(
          title: 'Settings',
          icon: Icons.settings,
          color: const Color(0xFFE57373),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate()
      .scale(duration: 600.ms, delay: 400.ms)
      .then()
      .shimmer(duration: 1200.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          context,
          'Manage Students',
          '/student_management',
          Icons.people_alt,
          const Color(0xFF312E81),
          const Color(0xFF4F46E5),
        ),
        _buildActionCard(
          context,
          'Assign Tasks',
          '/task_assignment',
          Icons.assignment_add,
          const Color(0xFF831843),
          const Color(0xFFDB2777),
        ),
        _buildActionCard(
          context,
          'View Reports',
          '/reports',
          Icons.analytics,
          const Color(0xFF115E59),
          const Color(0xFF0D9488),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String label, String route,
      IconData icon, Color startColor, Color endColor) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: endColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms, delay: 600.ms);
  }
}
