import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await supabase
          .from('users')
          .select()
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

  Future<void> _addStudent() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'role': 'student',
      };

      await supabase.from('users').insert(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
        _nameController.clear();
        _emailController.clear();
        await _fetchStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStudent() async {
    if (_selectedStudentId == null ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
      };

      await supabase
          .from('users')
          .update(userData)
          .eq('id', _selectedStudentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
        _nameController.clear();
        _emailController.clear();
        setState(() => _selectedStudentId = null);
        await _fetchStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteStudent(String studentId) async {
    try {
      await supabase.from('users').delete().eq('id', studentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted successfully')),
        );
        await _fetchStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting student: $e')),
        );
      }
    }
  }

  void _editStudent(Map<String, dynamic> student) {
    setState(() {
      _selectedStudentId = student['id'];
      _nameController.text = student['name'];
      _emailController.text = student['email'];
    });
  }

  List<Map<String, dynamic>> _getFilteredStudents() {
    if (_searchController.text.isEmpty) {
      return _students;
    }
    final searchTerm = _searchController.text.toLowerCase();
    return _students.where((student) {
      return student['name'].toString().toLowerCase().contains(searchTerm) ||
          student['email'].toString().toLowerCase().contains(searchTerm);
    }).toList();
  }

  Future<void> _uploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null) {
      try {
        var bytes = result.files.single.bytes;
        var excel = Excel.decodeBytes(bytes!);
        for (var row in excel['Sheet1'].rows.skip(1)) {
          final name = row[0]?.value.toString()?.trim();
          final email = row[1]?.value.toString()?.trim();
          final password = 'default123';
          if (name != null && email != null) {
            final response = await supabase.auth.signUp(
              email: email,
              password: password,
              data: {'name': name, 'role': 'student'},
            );
            if (response.user != null) {
              await supabase.from('users').insert({
                'id': response.user!.id,
                'name': name,
                'email': email,
                'password': password,
                'role': 'student',
              });
            }
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Students uploaded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _getFilteredStudents();
    
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
                      'Student Management',
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
                              _selectedStudentId == null ? 'Add New Student' : 'Edit Student',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate()
                              .fadeIn(duration: 500.ms)
                              .slideX(begin: -0.2),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Student Name',
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF64B5F6)),
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
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF64B5F6)),
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
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : (_selectedStudentId == null ? _addStudent : _updateStudent),
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
                                        : Text(
                                            _selectedStudentId == null ? 'Add Student' : 'Update Student',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ).animate()
                                  .scale(duration: 500.ms, delay: 600.ms)
                                  .then()
                                  .shimmer(duration: 1200.ms),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _uploadExcel,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF64B5F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Upload Excel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ).animate()
                                  .scale(duration: 500.ms, delay: 800.ms)
                                  .then()
                                  .shimmer(duration: 1200.ms),
                                if (_selectedStudentId != null) ...[
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedStudentId = null;
                                        _nameController.clear();
                                        _emailController.clear();
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ).animate()
                                    .scale(duration: 500.ms, delay: 1000.ms)
                                    .then()
                                    .shimmer(duration: 1200.ms),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
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
                                Text(
                                  'Student List',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ).animate()
                                  .fadeIn(duration: 500.ms)
                                  .slideX(begin: -0.2),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  onPressed: _fetchStudents,
                                ).animate()
                                  .scale(duration: 600.ms)
                                  .then()
                                  .shimmer(duration: 1200.ms),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search Students',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF64B5F6)),
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
                              onChanged: (value) => setState(() {}),
                            ).animate()
                              .fadeIn(duration: 500.ms)
                              .slideX(begin: -0.2),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: filteredStudents.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No students found',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: filteredStudents.length,
                                      itemBuilder: (context, index) {
                                        final student = filteredStudents[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(0xFF64B5F6),
                                              child: Text(
                                                student['name'][0].toUpperCase(),
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            title: Text(
                                              student['name'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              student['email'],
                                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Color(0xFF64B5F6)),
                                                  onPressed: () => _editStudent(student),
                                                ).animate()
                                                  .scale(duration: 300.ms)
                                                  .then()
                                                  .shimmer(duration: 1200.ms),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor: const Color(0xFF1E1E2E),
                                                      title: const Text(
                                                        'Delete Student',
                                                        style: TextStyle(color: Colors.white),
                                                      ),
                                                      content: Text(
                                                        'Are you sure you want to delete ${student['name']}?',
                                                        style: const TextStyle(color: Colors.white70),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(color: Colors.white70),
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            _deleteStudent(student['id']);
                                                            Navigator.pop(context);
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                          ),
                                                          child: const Text('Delete'),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ).animate()
                                                  .scale(duration: 300.ms)
                                                  .then()
                                                  .shimmer(duration: 1200.ms),
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
            ],
          ),
        ),
      ),
    );
  }
}