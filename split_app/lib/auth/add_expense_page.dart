import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

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
      appBar: AppBar(
        title: Text(
          'Add Expense',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D0EB5), Color(0xFF4059F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WaveWidget(
              config: CustomConfig(
                gradients: [
                  [const Color(0xFF6D0EB5), const Color(0xFF4059F1)],
                  [const Color(0xFF4059F1), const Color(0xFF6D0EB5)],
                ],
                durations: [35000, 19440],
                heightPercentages: [0.20, 0.23],
                blur: const MaskFilter.blur(BlurStyle.solid, 10),
                gradientBegin: Alignment.topLeft,
                gradientEnd: Alignment.bottomRight,
              ),
              waveAmplitude: 0,
              size: const Size(double.infinity, double.infinity),
            ),
          ),
          Positioned.fill(
            child: FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final members = List<String>.from(data['members'] ?? []);
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Text(
                              'Add Expense',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _expenseTitleController,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                labelStyle: GoogleFonts.openSans(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _expenseAmountController,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                labelStyle: GoogleFonts.openSans(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _paidBy,
                              items:
                                  members
                                      .map(
                                        (uid) => DropdownMenuItem(
                                          value: uid,
                                          child: FutureBuilder<
                                            DocumentSnapshot
                                          >(
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
                                              if (userData == null)
                                                return Text(uid);
                                              return Text(
                                                userData['username'] ??
                                                    userData['email'] ??
                                                    uid,
                                                style: GoogleFonts.openSans(),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) => setState(() => _paidBy = val),
                              decoration: InputDecoration(
                                labelText: 'Paid By',
                                labelStyle: GoogleFonts.openSans(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text(
                                'Date: ${DateFormat('yyyy-MM-dd').format(_expenseDate)}',
                                style: GoogleFonts.openSans(),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _expenseDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setState(() => _expenseDate = picked);
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _expenseNotesController,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                labelStyle: GoogleFonts.openSans(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (expenseError.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  expenseError,
                                  style: GoogleFonts.openSans(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            expenseLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                  onPressed: () => addExpense(members),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4059F1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 32,
                                    ),
                                  ),
                                  child: Text(
                                    'Add Expense',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
