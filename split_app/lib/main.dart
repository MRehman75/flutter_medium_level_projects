import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore CRUD',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FirestoreCrudPage(),
    );
  }
}

class FirestoreCrudPage extends StatefulWidget {
  @override
  _FirestoreCrudPageState createState() => _FirestoreCrudPageState();
}

class _FirestoreCrudPageState extends State<FirestoreCrudPage> {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  Future<void> addUser() async {
    if (nameController.text.isEmpty || ageController.text.isEmpty) return;
    await users.add({
      'name': nameController.text,
      'age': int.tryParse(ageController.text) ?? 0,
    });
    nameController.clear();
    ageController.clear();
  }

  Future<void> updateUser(String docId, String newName, int newAge) async {
    await users.doc(docId).update({'name': newName, 'age': newAge});
  }

  Future<void> deleteUser(String docId) async {
    await users.doc(docId).delete();
  }

  void showUpdateDialog(DocumentSnapshot doc) {
    final updateNameController = TextEditingController(text: doc['name']);
    final updateAgeController = TextEditingController(
      text: doc['age'].toString(),
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: updateNameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: updateAgeController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await updateUser(
                    doc.id,
                    updateNameController.text,
                    int.tryParse(updateAgeController.text) ?? 0,
                  );
                  Navigator.pop(context);
                },
                child: Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore CRUD Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: addUser, child: Text('Add')),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: users.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No users found.'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return ListTile(
                        title: Text(doc['name']),
                        subtitle: Text('Age: ${doc['age']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => showUpdateDialog(doc),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => deleteUser(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
