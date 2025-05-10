import 'package:flutter/material.dart';
import 'dart:io';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';





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
      duration: Duration(seconds: 3),
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

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
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

class WishlistTransaction {
  final String title;
  final double targetAmount;
  double currentAmount;

  WishlistTransaction({
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
  });
}

class Wishlist {
  String title;
  double targetAmount;
  double currentAmount;

  Wishlist({
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
  });

  void addSaving(double amount) {
    currentAmount += amount;
  }
}

class WishlistItem {
  final String name;
  final double targetAmount;
  final DateTime targetDate;
  final String description;
  final String? image;
  double currentAmount;


  WishlistItem({
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    required this.description,
    this.image,
    this.currentAmount = 0.0,
  });

  void addSaving(double amount) {
    currentAmount += amount;
  }

  bool get isGoalAchieved => currentAmount >= targetAmount;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'targetDate': targetDate.toIso8601String(),
      'description': description,
      'image': image,
      'currentAmount': currentAmount,
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      name: json['name'],
      targetAmount: json['targetAmount'],
      targetDate: DateTime.parse(json['targetDate']),
      description: json['description'],
      image: json['image'],
      currentAmount: json['currentAmount'] ?? 0.0,
    );
  }
}


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<Transaction> _transactions = [];
  final List<WishlistItem> _wishlist = [];
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = true;

  late TabController _tabController;
  final currencyFormat = NumberFormat("#,##0", "id_ID");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
    _loadWishlist();
  }

  // Saving and loading transactions
  void _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> transactionsJson = _transactions.map((tx) => json.encode({
      'title': tx.title,
      'amount': tx.amount,
      'isIncome': tx.isIncome,
    })).toList();
    prefs.setStringList('transactions', transactionsJson);
  }

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

    _saveTransactions();

    _titleController.clear();
    _amountController.clear();
  }

  // Wishlist handling
  void _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> wishlistJson = _wishlist.map((item) => json.encode({
      'name': item.name,
      'targetAmount': item.targetAmount,
      'targetDate': item.targetDate.toIso8601String(),
      'description': item.description,
      'image': item.image,
    })).toList();
    prefs.setStringList('wishlist', wishlistJson);
  }

  void _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? wishlistJson = prefs.getStringList('wishlist');
    if (wishlistJson != null) {
      setState(() {
        _wishlist.clear();
        _wishlist.addAll(wishlistJson.map((itemJson) {
          final itemMap = json.decode(itemJson);
          return WishlistItem(
            name: itemMap['name'],
            targetAmount: itemMap['targetAmount'],
            targetDate: DateTime.parse(itemMap['targetDate']),
            description: itemMap['description'],
            image: itemMap['image'],
          );
        }).toList());
      });
    }
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
      length: 3,
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
              Tab(text: 'Wishlist'),
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
            WishlistScreen(wishlist: _wishlist),
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

class WishlistScreen extends StatefulWidget {
  final List<WishlistItem> wishlist;
  WishlistScreen({Key? key, required this.wishlist}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    loadWishlistFromPrefs();
  }

  Future<void> loadWishlistFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getStringList('wishlist') ?? [];

    final loadedWishlist = wishlistJson.map((itemString) {
      final itemMap = json.decode(itemString);
      return WishlistItem(
        name: itemMap['name'],
        targetAmount: itemMap['targetAmount'],
        targetDate: DateTime.parse(itemMap['targetDate']),
        description: itemMap['description'],
        image: itemMap['image'],
        currentAmount: itemMap['currentAmount'] ?? 0,
      );
    }).toList();

    setState(() {
      widget.wishlist.clear();
      widget.wishlist.addAll(loadedWishlist);
    });
  }

  Future<void> saveWishlistToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = widget.wishlist.map((item) => json.encode({
      'name': item.name,
      'targetAmount': item.targetAmount,
      'targetDate': item.targetDate.toIso8601String(),
      'description': item.description,
      'image': item.image,
      'currentAmount': item.currentAmount,
    })).toList();
    prefs.setStringList('wishlist', wishlistJson);
  }

  void _addSaving(WishlistItem item) async {
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) return;

    setState(() {
      item.addSaving(amount);
    });

    await saveWishlistToPrefs();
    _amountController.clear();
  }

  void _deleteWishlistItem(WishlistItem item) async {
    setState(() {
      widget.wishlist.remove(item);
    });
    await saveWishlistToPrefs();
  }

  void _showDeleteConfirmationDialog(WishlistItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Hapus Wishlist'),
          content: Text('Apakah kamu yakin ingin menghapus wishlist "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteWishlistItem(item);
                Navigator.of(ctx).pop();
              },
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Tambah Wishlist'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nama Wishlist'),
                ),
                TextField(
                  controller: _targetAmountController,
                  decoration: InputDecoration(labelText: 'Target Dana'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                ),
                SizedBox(height: 10),
                _selectedImage != null
                    ? Image.file(_selectedImage!, width: 100, height: 100)
                    : Text("Belum ada gambar"),
                TextButton.icon(
                  icon: Icon(Icons.image, color: Colors.teal),
                  label: Text("Pilih Gambar"),
                  onPressed: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text;
                final targetAmount = double.tryParse(_targetAmountController.text.replaceAll('.', '')) ?? 0;
                final description = _descriptionController.text;

                if (name.isEmpty || targetAmount <= 0) return;

                final newItem = WishlistItem(
                  name: name,
                  targetAmount: targetAmount,
                  targetDate: DateTime.now(),
                  description: description,
                  image: _selectedImage?.path,
                );

                setState(() {
                  widget.wishlist.add(newItem);
                });

                await saveWishlistToPrefs();

                _nameController.clear();
                _targetAmountController.clear();
                _descriptionController.clear();
                _selectedImage = null;

                Navigator.of(ctx).pop();
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSavingDialog(WishlistItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Tambahkan Dana ke ${item.name}'),
          content: TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: 'Jumlah Dana'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _addSaving(item);
                Navigator.of(ctx).pop();
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text("Wishlist")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: widget.wishlist.isEmpty
            ? Center(child: Text("Belum ada item wishlist."))
            : ListView.builder(
          itemCount: widget.wishlist.length,
          itemBuilder: (ctx, index) {
            final item = widget.wishlist[index];
            final progress = (item.currentAmount / item.targetAmount).clamp(0.0, 1.0);
            final isComplete = item.currentAmount >= item.targetAmount;

            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: ListTile(
                contentPadding: EdgeInsets.all(8),
                leading: item.image == null
                    ? Icon(Icons.image, color: Colors.teal)
                    : Image.file(
                  File(item.image!),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(item.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      color: Colors.teal,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    SizedBox(height: 4),
                    Text('${currencyFormat.format(item.currentAmount)} / ${currencyFormat.format(item.targetAmount)}'),
                    if (isComplete)
                      Text(
                        '🎉 Selamat, target terpenuhi!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Colors.teal),
                      onPressed: () {
                        _showAddSavingDialog(item);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(item);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

class PieChartScreen extends StatefulWidget {
  final double income;
  final double expense;

  PieChartScreen({required this.income, required this.expense});

  @override
  _PieChartScreenState createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String selectedFilter = 'Bulanan';
  final List<String> filterOptions = ['Harian', 'Mingguan', 'Bulanan'];

  // Data dummy kategori keuangan (kamu bisa ganti dengan data dari backend/DB)
  Map<String, double> categoryData = {
    'Gaji': 3000000,
    'Belanja': 1000000,
    'Transportasi': 1000000,
  };

  @override
  Widget build(BuildContext context) {
    final double total = widget.income + widget.expense;
    final double incomePercent = total == 0 ? 0 : (widget.income / total) * 100;
    final double expensePercent = total == 0 ? 0 : (widget.expense / total) * 100;

    final Map<String, double> dataMap = {
      "Pemasukan": widget.income,
      "Pengeluaran": widget.expense,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Analisis Keuangan", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 20),

                // Dropdown Filter Waktu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Periode:"),
                    DropdownButton<String>(
                      value: selectedFilter,
                      items: filterOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value!;
                          //
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Pie Chart Utama
                if (widget.income == 0 && widget.expense == 0)
                  Center(child: Text("Belum ada data untuk ditampilkan.", style: TextStyle(color: Colors.grey)))
                else ...[
                  PieChart(
                    dataMap: dataMap,
                    animationDuration: Duration(milliseconds: 800),
                    chartLegendSpacing: 32,
                    chartRadius: MediaQuery.of(context).size.width / 1.6,
                    colorList: [Colors.green, Colors.red],
                    chartType: ChartType.ring,
                    ringStrokeWidth: 32,
                    legendOptions: LegendOptions(
                      showLegends: true,
                      legendPosition: LegendPosition.right,
                    ),
                    chartValuesOptions: ChartValuesOptions(
                      showChartValues: false,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Komposisi: Pemasukan ${incomePercent.toStringAsFixed(1)}% | Pengeluaran ${expensePercent.toStringAsFixed(1)}%",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  Text("Total Pemasukan: ${currencyFormat.format(widget.income)}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  SizedBox(height: 8),
                  Text("Total Pengeluaran: ${currencyFormat.format(widget.expense)}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
                ],

                SizedBox(height: 30),

              ]
            ),
          ),
        ),
      ),
    );
  }
}