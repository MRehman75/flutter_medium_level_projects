import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

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
      // Notify all other group members
      final groupDoc =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();
      final members = List<String>.from(groupDoc['members'] ?? []);
      for (final memberId in members) {
        if (memberId != userId) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .collection('notifications')
              .add({
                'type': 'join',
                'groupId': widget.groupId,
                'message':
                    'User ${userDoc['username'] ?? userDoc['email'] ?? userId} joined the group.',
                'timestamp': FieldValue.serverTimestamp(),
                'read': false,
              });
        }
      }
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
    // (Removed insufficient funds check to allow negative balance)
    // final payerDoc = await FirebaseFirestore.instance.collection('users').doc(paidBy).get();
    // final payerData = payerDoc.data() as Map<String, dynamic>?;
    // final payerCash = (payerData?['cash'] ?? 0.0) as num;
    // if (payerCash < amount) {
    //   setState(() {
    //     expenseError = 'Payer does not have enough cash.';
    //     expenseLoading = false;
    //   });
    //   return;
    // }
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
      // Notify all other group members
      for (final memberId in members) {
        if (memberId != paidBy) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .collection('notifications')
              .add({
                'type': 'expense',
                'groupId': widget.groupId,
                'message': "A new expense '$title' was added.",
                'timestamp': FieldValue.serverTimestamp(),
                'read': false,
              });
        }
      }
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
      appBar: AppBar(
        title: Text(
          'Group Details',
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
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                final name = data['name'] ?? '';
                final admin = data['admin'] ?? '';
                final members = List<String>.from(data['members'] ?? []);
                final isAdmin = user != null && user.uid == admin;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group Name',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  name,
                                  style: GoogleFonts.openSans(fontSize: 18),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Admin',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FutureBuilder<DocumentSnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(admin)
                                          .get(),
                                  builder: (context, adminSnap) {
                                    if (!adminSnap.hasData)
                                      return const Text('Loading...');
                                    final adminData =
                                        adminSnap.data!.data()
                                            as Map<String, dynamic>?;
                                    final adminName =
                                        adminData?['username'] ??
                                        adminData?['email'] ??
                                        admin;
                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(
                                            0xFF4059F1,
                                          ),
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          adminName,
                                          style: GoogleFonts.openSans(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Members',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...members.map(
                                  (uid) => FutureBuilder<DocumentSnapshot>(
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
                                      final name =
                                          userData?['username'] ??
                                          userData?['email'] ??
                                          uid;
                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(
                                              0xFF6D0EB5,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            name,
                                            style: GoogleFonts.openSans(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Expense History',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(widget.groupId)
                                  .collection('expenses')
                                  .orderBy('date', descending: true)
                                  .get(),
                          builder: (context, snap) {
                            if (!snap.hasData)
                              return const CircularProgressIndicator();
                            final docs = snap.data!.docs;
                            if (docs.isEmpty)
                              return Text(
                                'No expenses yet.',
                                style: GoogleFonts.openSans(),
                              );
                            return Column(
                              children:
                                  docs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(
                                            0xFF4059F1,
                                          ),
                                          child: Icon(
                                            Icons.attach_money,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(
                                          data['title'] ?? '',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Amount: ${data['amount']} | Paid by: ${data['paidBy']} | Date: ${DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate())}',
                                          style: GoogleFonts.openSans(),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isAdmin)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Delete Expense',
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(data['paidBy'])
                                                      .update({
                                                        'cash':
                                                            FieldValue.increment(
                                                              (data['amount']
                                                                      as num)
                                                                  .toDouble(),
                                                            ),
                                                      });
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('groups')
                                                      .doc(widget.groupId)
                                                      .collection('expenses')
                                                      .doc(doc.id)
                                                      .delete();
                                                },
                                              ),
                                            if (data['notes'] != null &&
                                                data['notes']
                                                    .toString()
                                                    .isNotEmpty)
                                              const Icon(Icons.note),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF4059F1),
                  size: 32,
                ),
                tooltip: 'Add Expense',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/add_expense', arguments: widget.groupId);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.dashboard,
                  color: Color(0xFF6D0EB5),
                  size: 32,
                ),
                tooltip: 'Dashboard',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/group_dashboard', arguments: widget.groupId);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble,
                  color: Color(0xFF4059F1),
                  size: 32,
                ),
                tooltip: 'Group Chat',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/group_chat', arguments: widget.groupId);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.person_add,
                  color: Color(0xFF4059F1),
                  size: 32,
                ),
                tooltip: 'Invite User',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/invite_user', arguments: widget.groupId);
                },
              ),
            ],
          ),
        ),
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
