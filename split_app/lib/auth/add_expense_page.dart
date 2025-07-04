import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddExpensePage extends StatefulWidget {
  final String groupId;
  const AddExpensePage({super.key, required this.groupId});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _expenseTitleController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _expenseNotesController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  String? _paidBy;
  String expenseError = '';
  bool expenseLoading = false;

  Future<void> addExpense(List<String> members) async {
    setState(() {
      expenseError = '';
      expenseLoading = true;
    });
    final title = _expenseTitleController.text.trim();
    final amount = double.tryParse(_expenseAmountController.text.trim());
    final notes = _expenseNotesController.text.trim();
    final paidBy = _paidBy;
    if (title.isEmpty || amount == null || paidBy == null) {
      setState(() {
        expenseError = 'Fill all required fields';
        expenseLoading = false;
      });
      return;
    }
    // Deduct cash from payer (can go negative)
    await FirebaseFirestore.instance.collection('users').doc(paidBy).update({
      'cash': FieldValue.increment(-amount),
    });
    final splitAmount = (amount / members.length).toStringAsFixed(2);
    final split = {for (var m in members) m: double.parse(splitAmount)};
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .add({
            'title': title,
            'amount': amount,
            'paidBy': paidBy,
            'date': _expenseDate,
            'notes': notes,
            'split': split,
          });
      setState(() {
        _expenseTitleController.clear();
        _expenseAmountController.clear();
        _expenseNotesController.clear();
        _paidBy = null;
        _expenseDate = DateTime.now();
        expenseLoading = false;
      });
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        expenseError = 'Failed to add expense';
        expenseLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final members = List<String>.from(data['members'] ?? []);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                TextField(
                  controller: _expenseTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _expenseAmountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: _paidBy,
                  items:
                      members
                          .map(
                            (uid) => DropdownMenuItem(
                              value: uid,
                              child: FutureBuilder<DocumentSnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .get(),
                                builder: (context, userSnap) {
                                  if (!userSnap.hasData)
                                    return const Text('Loading...');
                                  final userData =
                                      userSnap.data!.data()
                                          as Map<String, dynamic>?;
                                  if (userData == null) return Text(uid);
                                  return Text(
                                    userData['username'] ??
                                        userData['email'] ??
                                        uid,
                                  );
                                },
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _paidBy = val),
                  decoration: const InputDecoration(labelText: 'Paid By'),
                ),
                ListTile(
                  title: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(_expenseDate)}',
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expenseDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _expenseDate = picked);
                  },
                ),
                TextField(
                  controller: _expenseNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                if (expenseError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      expenseError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                expenseLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: () => addExpense(members),
                      child: const Text('Add Expense'),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
