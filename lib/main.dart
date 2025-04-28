import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(KeuanganApp());
}

class KeuanganApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KeuanganKu',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.teal[50],
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).copyWith(
          titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: GoogleFonts.poppins(fontSize: 16),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 3), // Biar lebih terasa animasinya
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Tambahkan listener untuk tahu kapan animasi selesai
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Setelah animasi selesai, baru masuk ke HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[400],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: Image.asset(
                    'assets/images/wallet.png',
                    height: 200,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'KeuanganKu',
                  style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Transaction {
  final String title;
  final double amount;
  final bool isIncome;

  Transaction({
    required this.title,
    required this.amount,
    required this.isIncome,
  });
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<Transaction> _transactions = [];
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = true;

  late TabController _tabController;
  final currencyFormat = NumberFormat("#,##0", "id_ID");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();  // Memuat transaksi saat aplikasi dimulai
  }

  // Menyimpan transaksi ke shared preferences
  void _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> transactionsJson = _transactions.map((tx) => json.encode({
      'title': tx.title,
      'amount': tx.amount,
      'isIncome': tx.isIncome,
    })).toList();
    prefs.setStringList('transactions', transactionsJson);
  }

  // Memuat transaksi dari shared preferences
  void _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? transactionsJson = prefs.getStringList('transactions');
    if (transactionsJson != null) {
      setState(() {
        _transactions.clear();
        _transactions.addAll(transactionsJson.map((txJson) {
          final txMap = json.decode(txJson);
          return Transaction(
            title: txMap['title'],
            amount: txMap['amount'],
            isIncome: txMap['isIncome'],
          );
        }).toList());
      });
    }
  }

  void _addTransaction() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

    if (title.isEmpty || amount <= 0) return;

    setState(() {
      _transactions.add(Transaction(
        title: title,
        amount: amount,
        isIncome: _isIncome,
      ));
    });

    _saveTransactions();  // Simpan transaksi setelah ditambahkan

    _titleController.clear();
    _amountController.clear();
  }

  void _showCategoryPicker() {
    final List<String> incomeCategories = [
      'Gaji',
      'Bonus',
      'Penjualan',
      'Lainnya',
    ];

    final List<String> expenseCategories = [
      'Makan',
      'Jajan',
      'Transportasi',
      'Belanja',
      'Hiburan',
      'Lainnya',
    ];

    final List<String> categories = _isIncome ? incomeCategories : expenseCategories;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView(
          children: categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                setState(() {
                  _titleController.text = category;
                });
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }

  double get _totalBalance {
    return _transactions.fold(0.0, (sum, tx) => tx.isIncome ? sum + tx.amount : sum - tx.amount);
  }

  double get _totalIncome {
    return _transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get _totalExpense {
    return _transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text('KeuanganKu'),
          bottom: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Transaksi'),
              Tab(text: 'Analisis'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 6,
                    margin: EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.teal, size: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Saldo Saat Ini', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                              Text('Rp ${currencyFormat.format(_totalBalance)}',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            readOnly: true,
                            onTap: _showCategoryPicker,
                            decoration: InputDecoration(
                              labelText: 'Judul',
                              prefixIcon: Icon(Icons.edit),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Jumlah (Rp)',
                              prefixIcon: Icon(Icons.money),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text("Jenis: "),
                              DropdownButton<bool>(
                                value: _isIncome,
                                items: [
                                  DropdownMenuItem(child: Text("Pemasukan"), value: true),
                                  DropdownMenuItem(child: Text("Pengeluaran"), value: false),
                                ],
                                onChanged: (val) => setState(() => _isIncome = val!),
                              ),
                              Spacer(),
                              ElevatedButton.icon(
                                onPressed: _addTransaction,
                                icon: Icon(Icons.add),
                                label: Text("Tambah"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TransactionList(transactions: _transactions),
                ],
              ),
            ),
            PieChartScreen(income: _totalIncome, expense: _totalExpense),
          ],
        ),
      ),
    );
  }
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "id_ID");

    return transactions.isEmpty
        ? Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(child: Text("Belum ada data transaksi.")),
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (ctx, index) {
        final tx = transactions[index];
        return Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 24,
              child: Image.asset(
                tx.isIncome
                    ? 'assets/images/income_icon.png'
                    : 'assets/images/expense_icon.png',
                width: 28,
                height: 28,
              ),
            ),

            title: Text(tx.title),
            subtitle: Text("Rp ${currencyFormat.format(tx.amount)}"),
          ),
        );
      },
    );
  }
}

class PieChartScreen extends StatelessWidget {
  final double income;
  final double expense;

  PieChartScreen({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final Map<String, double> dataMap = {
      "Pemasukan": income,
      "Pengeluaran": expense,
    };

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text("Analisis Keuangan", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 20),
                if (income == 0 && expense == 0)
                  Text("Belum ada data untuk ditampilkan.", style: TextStyle(color: Colors.grey))
                else ...[
                  PieChart(
                    dataMap: dataMap,
                    animationDuration: Duration(milliseconds: 800),
                    chartLegendSpacing: 32,
                    chartRadius: MediaQuery.of(context).size.width / 1.5,
                    colorList: [Colors.green, Colors.red],
                    chartType: ChartType.ring,
                    ringStrokeWidth: 32,
                    legendOptions: LegendOptions(
                      showLegends: true,
                      legendPosition: LegendPosition.right,
                    ),
                    chartValuesOptions: ChartValuesOptions(
                      showChartValues: false, // Ini untuk menghilangkan angka di pie
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Pemasukan: ${currencyFormat.format(income)}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                      SizedBox(height: 8),
                      Text("Total Pengeluaran: ${currencyFormat.format(expense)}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
                    ],
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
