import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AmarHisabApp());
}

class Entry {
  Entry({required this.title, required this.amount, required this.isIncome, required this.date});
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'title': title, 'amount': amount, 'isIncome': isIncome, 'date': date.toIso8601String()
  };
  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    title: json['title'], amount: (json['amount'] as num).toDouble(),
    isIncome: json['isIncome'], date: DateTime.parse(json['date']));
}

class AmarHisabApp extends StatefulWidget {
  const AmarHisabApp({super.key});
  @override
  State<AmarHisabApp> createState() => _AmarHisabAppState();
}

class _AmarHisabAppState extends State<AmarHisabApp> {
  bool bangla = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Amar Hisab',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor:Colors.deepPurple), Color(0xff159447)),
      scaffoldBackgroundColor: const Color(0xfff6f8fb), useMaterial3: true,
      fontFamily: bangla ? null : 'Roboto'),
    home: HomePage(bangla: bangla, onLanguageChanged: (v) => setState(() => bangla = v)),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.bangla, required this.onLanguageChanged});
  final bool bangla;
  final ValueChanged<bool> onLanguageChanged;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Entry> entries = [];
  int tab = 0;
  bool loaded = false;

  String t(String bn, String en) => widget.bangla ? bn : en;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('entries') ?? '[]';
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    if (!mounted) return;
    setState(() { entries.addAll(decoded.map(Entry.fromJson)); loaded = true; });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('entries', jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  double get income => entries.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
  double get expense => entries.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
  double get balance => income - expense;

  String money(double value) => '৳ ${value.toStringAsFixed(0)}';

  Future<void> _addEntry(bool isIncome) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(isIncome ? t('আয় যোগ করুন', 'Add income') : t('খরচ যোগ করুন', 'Add expense')),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: title, autofocus: true,
          decoration: InputDecoration(labelText: t('বিবরণ', 'Description'), hintText: t('যেমন: বেতন / বাজার', 'e.g. Salary / Groceries')),
          validator: (v) => (v == null || v.trim().isEmpty) ? t('বিবরণ লিখুন', 'Enter a description') : null),
        const SizedBox(height: 12),
        TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t('টাকার পরিমাণ', 'Amount (BDT)'), prefixText: '৳ '),
          validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) <= 0) ? t('সঠিক পরিমাণ লিখুন', 'Enter a valid amount') : null),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('বাতিল', 'Cancel'))),
        FilledButton(onPressed: () {
          if (!formKey.currentState!.validate()) return;
          setState(() => entries.insert(0, Entry(title: title.text.trim(), amount: double.parse(amount.text), isIncome: isIncome, date: DateTime.now())));
          _save(); Navigator.pop(ctx);
        }, child: Text(t('সংরক্ষণ', 'Save')))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.white,
        title: Row(children: [
          const Icon(Icons.account_balance_wallet, color: Color(0xff159447), size: 30),
          const SizedBox(width: 9),
          const Text('Amar ', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xff172333))),
          const Text('Hisab', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xff159447))),
        ]),
        actions: [TextButton(onPressed: () => widget.onLanguageChanged(!widget.bangla),
          child: Text(widget.bangla ? 'English' : 'বাংলা', style: const TextStyle(fontWeight: FontWeight.bold)))],
      ),
      body: IndexedStack(index: tab, children: [
        _dashboard(), _transactions(), _simplePage(t('পরিসংখ্যান', 'Statistics'), Icons.bar_chart),
        _simplePage(t('সঞ্চয়', 'Savings'), Icons.savings_outlined),
        _simplePage(t('সেটিংস', 'Settings'), Icons.settings_outlined),
      ]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t('হোম', 'Home')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: t('লেনদেন', 'Transactions')),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: t('পরিসংখ্যান', 'Stats')),
          NavigationDestination(icon: const Icon(Icons.savings_outlined), label: t('সঞ্চয়', 'Savings')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: t('সেটিংস', 'Settings')),
        ]),
    );
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xff159447), Color(0xff08723a)]),
      borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('মোট ব্যালেন্স', 'Total balance'), style: const TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 8),
        Text(money(balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(t('আপনার অর্থ, আপনার নিয়ন্ত্রণ।', 'Your money, your control.'), style: const TextStyle(color: Colors.white70)),
      ])),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _summary(t('মোট আয়', 'Income'), income, Icons.arrow_downward, const Color(0xff159447))),
      const SizedBox(width: 10),
      Expanded(child: _summary(t('মোট খরচ', 'Expenses'), expense, Icons.arrow_upward, Colors.red)),
    ]),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: FilledButton.icon(onPressed: () => _addEntry(true), icon: const Icon(Icons.add), label: Text(t('আয় যোগ', 'Add income')))),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton.icon(onPressed: () => _addEntry(false), icon: const Icon(Icons.remove), label: Text(t('খরচ যোগ', 'Add expense')))),
    ]),
    const SizedBox(height: 24),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t('সাম্প্রতিক লেনদেন', 'Recent transactions'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      TextButton(onPressed: () => setState(() => tab = 1), child: Text(t('সব দেখুন', 'See all'))),
    ]),
    if (entries.isEmpty) _empty() else ...entries.take(4).map(_entryTile),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xffe9f7ee), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        const Icon(Icons.lock_outline, color: Color(0xff159447)),
        const SizedBox(width: 10),
        Expanded(child: Text(t('আপনার হিসাব এই ডিভাইসেই সংরক্ষিত হচ্ছে। নিয়মিত ব্যাকআপ রাখুন।', 'Your records are stored on this device. Keep regular backups.'), style: const TextStyle(fontSize: 12))),
      ])),
  ]);

  Widget _summary(String title, double value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color), const SizedBox(height: 8),
      Text(title, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(money(value), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
    ]));

  Widget _transactions() => ListView(padding: const EdgeInsets.all(16), children: [
    Text(t('সব লেনদেন', 'All transactions'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    if (entries.isEmpty) _empty() else ...entries.map(_entryTile),
  ]);

  Widget _entryTile(Entry e) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(leading: CircleAvatar(backgroundColor: e.isIncome ? const Color(0xffe5f6eb) : const Color(0xffffeeee),
      child: Icon(e.isIncome ? Icons.add : Icons.remove, color: e.isIncome ? const Color(0xff159447) : Colors.red)),
      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${e.date.day}/${e.date.month}/${e.date.year}'),
      trailing: Text('${e.isIncome ? '+' : '-'} ${money(e.amount)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: e.isIncome ? const Color(0xff159447) : Colors.red))));

  Widget _empty() => Padding(padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(children: [
      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
      const SizedBox(height: 8),
      Text(t('এখনো কোনো লেনদেন যোগ করা হয়নি।', 'No transactions yet.'), style: const TextStyle(color: Colors.black54)),
    ]));

  Widget _simplePage(String title, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 54, color: const Color(0xff159447)),
    const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text(t('এই ফিচারটি পরবর্তী ধাপে যোগ করা হবে।', 'This feature will be added in the next phase.'), style: const TextStyle(color: Colors.black54)),
  ]));
}
