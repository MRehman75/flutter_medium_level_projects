import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

class GroupDashboardPage extends StatelessWidget {
  final String groupId;
  const GroupDashboardPage({super.key, required this.groupId});

  Future<Map<String, dynamic>> calculateDashboard(List<String> members) async {
    final expensesSnap =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
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

  Future<Map<String, double>> calculateBalances(List<String> members) async {
    final expensesSnap =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
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

  List<Widget> whoOwesWhom(Map<String, double> balances, List<String> members) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Dashboard',
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
                      .doc(groupId)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final members = List<String>.from(data['members'] ?? []);
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
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
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Expenses',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rs. ${totalExpenses.toStringAsFixed(2)}',
                                      style: GoogleFonts.openSans(fontSize: 18),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Individual Share',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
                                            style: GoogleFonts.openSans(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: FutureBuilder<Map<String, double>>(
                              future: calculateBalances(members),
                              builder: (context, snap) {
                                if (!snap.hasData)
                                  return const CircularProgressIndicator();
                                final balances = snap.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Individual Balance',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    ...balances.entries.map(
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
                                            style: GoogleFonts.openSans(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                                  'Who Owes Whom',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<Map<String, double>>(
                                  future: calculateBalances(members),
                                  builder: (context, snap) {
                                    if (!snap.hasData)
                                      return const CircularProgressIndicator();
                                    final balances = snap.data!;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: whoOwesWhom(balances, members),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
