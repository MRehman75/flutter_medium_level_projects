import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage({super.key, required this.groupId});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _inviteController = TextEditingController();
  String error = '';
  bool loading = false;

  // Expense fields
  final _expenseTitleController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _expenseNotesController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  String? _paidBy;
  String expenseError = '';
  bool expenseLoading = false;

  Future<void> inviteUser() async {
    setState(() {
      error = '';
      loading = true;
    });
    final input = _inviteController.text.trim();
    if (input.isEmpty) {
      setState(() {
        error = 'Enter username or email';
        loading = false;
      });
      return;
    }
    try {
      // Find user by username or email
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input)
              .get();
      final emailQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: input)
              .get();
      final userDoc =
          userQuery.docs.isNotEmpty
              ? userQuery.docs.first
              : (emailQuery.docs.isNotEmpty ? emailQuery.docs.first : null);
      if (userDoc == null) {
        setState(() {
          error = 'User not found';
          loading = false;
        });
        return;
      }
      final userId = userDoc.id;
      // Add user to group members
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
            'members': FieldValue.arrayUnion([userId]),
          });
      // Add group to user's groups
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'groups': FieldValue.arrayUnion([widget.groupId]),
      });
      setState(() {
        loading = false;
        _inviteController.clear();
      });
    } catch (e) {
      setState(() {
        error = 'Failed to invite user';
        loading = false;
      });
    }
  }

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
    // Check payer's cash balance
    final payerDoc =
        await FirebaseFirestore.instance.collection('users').doc(paidBy).get();
    final payerData = payerDoc.data() as Map<String, dynamic>?;
    final payerCash = (payerData?['cash'] ?? 0.0) as num;
    if (payerCash < amount) {
      setState(() {
        expenseError = 'Payer does not have enough cash.';
        expenseLoading = false;
      });
      return;
    }
    final splitAmount = (amount / members.length).toStringAsFixed(2);
    final split = {for (var m in members) m: double.parse(splitAmount)};
    try {
      // Deduct cash from payer
      await FirebaseFirestore.instance.collection('users').doc(paidBy).update({
        'cash': FieldValue.increment(-amount),
      });
      // Add expense
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
    } catch (e) {
      setState(() {
        expenseError = 'Failed to add expense';
        expenseLoading = false;
      });
    }
  }

  Future<Map<String, double>> calculateBalances(List<String> members) async {
    final expensesSnap =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('expenses')
            .get();
    final Map<String, double> paid = {for (var m in members) m: 0.0};
    final Map<String, double> share = {for (var m in members) m: 0.0};
    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final paidBy = data['paidBy'] as String;
      final split = Map<String, dynamic>.from(data['split'] ?? {});
      paid[paidBy] = (paid[paidBy] ?? 0) + amount;
      split.forEach((uid, s) {
        share[uid] = (share[uid] ?? 0) + (s as num).toDouble();
      });
    }
    final Map<String, double> balances = {};
    for (var m in members) {
      balances[m] = (paid[m] ?? 0) - (share[m] ?? 0);
    }
    return balances;
  }

  Future<Map<String, dynamic>> calculateDashboard(List<String> members) async {
    final expensesSnap =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('expenses')
            .get();
    double totalExpenses = 0;
    final Map<String, double> share = {for (var m in members) m: 0.0};
    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final split = Map<String, dynamic>.from(data['split'] ?? {});
      totalExpenses += amount;
      split.forEach((uid, s) {
        share[uid] = (share[uid] ?? 0) + (s as num).toDouble();
      });
    }
    return {'totalExpenses': totalExpenses, 'share': share};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
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
          final name = data['name'] ?? '';
          final admin = data['admin'] ?? '';
          final members = List<String>.from(data['members'] ?? []);
          final isAdmin = user != null && user.uid == admin;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text('Group Name: $name', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Admin: $admin', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Text(
                  'Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...members.map(
                  (uid) => FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const Text('Loading...');
                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>?;
                      if (userData == null) return Text(uid);
                      return Text(
                        userData['username'] ?? userData['email'] ?? uid,
                      );
                    },
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _inviteController,
                    decoration: const InputDecoration(
                      labelText: 'Invite by username or email',
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: () => inviteUser(),
                        child: const Text('Invite User'),
                      ),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Add Expense',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
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
                const SizedBox(height: 32),
                const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder:
                          (context) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: calculateDashboard(members),
                              builder: (context, dashSnap) {
                                if (!dashSnap.hasData)
                                  return const CircularProgressIndicator();
                                final totalExpenses =
                                    dashSnap.data!['totalExpenses'] as double;
                                final share =
                                    dashSnap.data!['share']
                                        as Map<String, double>;
                                return SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dashboard',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'Total Expenses: Rs. ${totalExpenses.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Individual Share:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ...share.entries.map(
                                        (e) => FutureBuilder<DocumentSnapshot>(
                                          future:
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(e.key)
                                                  .get(),
                                          builder: (context, userSnap) {
                                            if (!userSnap.hasData)
                                              return const Text('Loading...');
                                            final userData =
                                                userSnap.data!.data()
                                                    as Map<String, dynamic>?;
                                            final name =
                                                userData?['username'] ??
                                                userData?['email'] ??
                                                e.key;
                                            return Text(
                                              '$name: Rs. ${e.value.toStringAsFixed(2)}',
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      FutureBuilder<Map<String, double>>(
                                        future: calculateBalances(members),
                                        builder: (context, snap) {
                                          if (!snap.hasData)
                                            return const CircularProgressIndicator();
                                          final balances = snap.data!;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Individual Balance:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              ...balances.entries.map(
                                                (e) => FutureBuilder<
                                                  DocumentSnapshot
                                                >(
                                                  future:
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(e.key)
                                                          .get(),
                                                  builder: (context, userSnap) {
                                                    if (!userSnap.hasData)
                                                      return const Text(
                                                        'Loading...',
                                                      );
                                                    final userData =
                                                        userSnap.data!.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >?;
                                                    final name =
                                                        userData?['username'] ??
                                                        userData?['email'] ??
                                                        e.key;
                                                    return Text(
                                                      '$name: Rs. ${e.value.toStringAsFixed(2)}',
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Individual Borrows:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              ..._whoOwesWhom(
                                                balances,
                                                members,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    );
                  },
                  child: const Text('Show Dashboard'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Expense History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('expenses')
                          .orderBy('date', descending: true)
                          .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) return const Text('No expenses yet.');
                    return Column(
                      children:
                          docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['title'] ?? ''),
                              subtitle: Text(
                                'Amount: ${data['amount']} | Paid by: ${data['paidBy']} | Date: ${DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate())}',
                              ),
                              trailing:
                                  data['notes'] != null &&
                                          data['notes'].toString().isNotEmpty
                                      ? Icon(Icons.note)
                                      : null,
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper: Who owes whom breakdown
  List<Widget> _whoOwesWhom(
    Map<String, double> balances,
    List<String> members,
  ) {
    // Separate creditors and debtors
    final creditors = <String, double>{};
    final debtors = <String, double>{};
    balances.forEach((uid, bal) {
      if (bal > 0.01)
        creditors[uid] = bal;
      else if (bal < -0.01)
        debtors[uid] = -bal;
    });
    final List<Widget> result = [];
    final Map<String, double> c = Map.from(creditors);
    final Map<String, double> d = Map.from(debtors);
    while (c.isNotEmpty && d.isNotEmpty) {
      final creditor = c.keys.first;
      final debtor = d.keys.first;
      final minAmount = c[creditor]! < d[debtor]! ? c[creditor]! : d[debtor]!;
      result.add(
        Row(
          children: [
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(debtor)
                        .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const Text('Loading...');
                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;
                  final debtorName =
                      userData?['username'] ?? userData?['email'] ?? debtor;
                  return Text(
                    debtorName,
                    style: const TextStyle(color: Colors.red),
                  );
                },
              ),
            ),
            const Text(' owes '),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(creditor)
                        .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const Text('Loading...');
                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>?;
                  final creditorName =
                      userData?['username'] ?? userData?['email'] ?? creditor;
                  return Text(
                    creditorName,
                    style: const TextStyle(color: Colors.green),
                  );
                },
              ),
            ),
            Text(' Rs. ${minAmount.toStringAsFixed(2)}'),
          ],
        ),
      );
      c[creditor] = c[creditor]! - minAmount;
      d[debtor] = d[debtor]! - minAmount;
      if (c[creditor]! < 0.01) c.remove(creditor);
      if (d[debtor]! < 0.01) d.remove(debtor);
    }
    if (result.isEmpty) {
      result.add(const Text('All settled up!'));
    }
    return result;
  }
}
