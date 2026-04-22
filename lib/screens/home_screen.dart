import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../app_language.dart';
import 'finance_adviser_chat_screen.dart';
import 'profile_settings_screen.dart';
import 'transactions_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _allTransactions = [
    {
      'icon': Icons.local_cafe,
      'title': 'Cafe Coffee Day',
      'amount': -150.0,
      'subtitle': 'Today, 11:45 AM',
      'method': 'Card ****1234',
      'color': Colors.orange,
      'type': 'Expense',
      'category': 'Food',
    },
    {
      'icon': Icons.directions_transit,
      'title': 'Metro Transit',
      'amount': -85.5,
      'subtitle': 'Yesterday, 3:20 PM',
      'method': 'UPI',
      'color': Colors.blue,
      'type': 'Expense',
      'category': 'Travel',
    },
    {
      'icon': Icons.attach_money,
      'title': 'Salary',
      'amount': 80000.0,
      'subtitle': '15 Oct, 09:30 AM',
      'method': 'Bank Transfer',
      'color': Colors.green,
      'type': 'Income',
      'category': 'Income',
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'Reliance Digital',
      'amount': -1200.0,
      'subtitle': '12 Oct, 10:15 AM',
      'method': 'Card ****5678',
      'color': Colors.purple,
      'type': 'Expense',
      'category': 'Shopping',
    },
    {
      'icon': Icons.fastfood,
      'title': 'Burger King',
      'amount': -250.0,
      'subtitle': '10 Oct, 01:15 PM',
      'method': 'UPI',
      'color': Colors.orange,
      'type': 'Expense',
      'category': 'Food',
    },
    {
      'icon': Icons.movie,
      'title': 'PVR Cinemas',
      'amount': -800.0,
      'subtitle': '09 Oct, 06:00 PM',
      'method': 'Card ****1234',
      'color': Colors.blueGrey,
      'type': 'Expense',
      'category': 'Entertainment',
    },
    {
      'icon': Icons.shopping_bag,
      'title': 'Zara',
      'amount': -4500.0,
      'subtitle': '05 Oct, 04:30 PM',
      'method': 'Card ****5678',
      'color': Colors.purple,
      'type': 'Expense',
      'category': 'Shopping',
    },
    {
      'icon': Icons.attach_money,
      'title': 'Freelance',
      'amount': 15000.0,
      'subtitle': '02 Oct, 11:30 AM',
      'method': 'Bank Transfer',
      'color': Colors.green,
      'type': 'Income',
      'category': 'Income',
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') return _allTransactions;
    if (_selectedFilter == 'Income' || _selectedFilter == 'Expense') {
      return _allTransactions
          .where((t) => t['type'] == _selectedFilter)
          .toList();
    }
    return _allTransactions
        .where((t) => t['category'] == _selectedFilter)
        .toList();
  }

  String _label(String key) => AppStrings.current.t(key);

  String _categoryLabel(String category) {
    switch (category) {
      case 'All':
        return _label('all');
      case 'Income':
        return _label('income');
      case 'Expense':
        return _label('expense');
      case 'Food':
        return _label('food');
      case 'Travel':
        return _label('travel');
      case 'Shopping':
        return _label('shopping');
      case 'Other':
        return _label('other');
      case 'Entertainment':
        return _label('entertainment');
      default:
        return category;
    }
  }

  bool isScanning = false;
  String? scannedUpiId;
  String? scannedMerchant;
  String? scannedMerchantCode;
  String? scannedAmount;
  String? scannedQrRaw;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;

  // For payment form
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  String selectedCategory = 'Food';
  List<String> categories = ['Food', 'Travel', 'Shopping', 'Other'];

  final UpiPay _upiPay = UpiPay();
  List<ApplicationMeta> _supportedUpiApps = [];
  bool isFetchingApps = false;

  List<MapEntry<String, String>> _parseRawQueryEntries(String query) {
    if (query.isEmpty) return const [];

    return query.split('&').where((part) => part.isNotEmpty).map((part) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex == -1) {
        return MapEntry(Uri.decodeQueryComponent(part), '');
      }

      final key = Uri.decodeQueryComponent(part.substring(0, separatorIndex));
      final value = Uri.decodeQueryComponent(
        part.substring(separatorIndex + 1),
      );
      return MapEntry(key, value);
    }).toList();
  }

  bool get _isPersonalUpiQr {
    if (scannedQrRaw == null) return true;

    final uri = Uri.tryParse(scannedQrRaw!);
    if (uri == null) return true;

    final queryParameters = uri.queryParametersAll;
    return !queryParameters.containsKey('mc') &&
        !queryParameters.containsKey('orgid') &&
        !queryParameters.containsKey('sign');
  }

  Uri _buildUpiUriFromRawQr(
    String rawQr, {
    required String amount,
    required String note,
  }) {
    final originalUri = Uri.parse(rawQr);
    final entries = _parseRawQueryEntries(originalUri.query);
    final updatedEntries = <MapEntry<String, String>>[];
    final seenKeys = <String>{};

    for (final entry in entries) {
      if (entry.key == 'am') {
        updatedEntries.add(MapEntry('am', amount));
        seenKeys.add('am');
        continue;
      }

      if (entry.key == 'tn') {
        if (note.isNotEmpty) {
          updatedEntries.add(MapEntry('tn', note));
          seenKeys.add('tn');
        }
        continue;
      }

      if (entry.key == 'cu') {
        updatedEntries.add(const MapEntry('cu', 'INR'));
        seenKeys.add('cu');
        continue;
      }

      updatedEntries.add(entry);
      seenKeys.add(entry.key);
    }

    if (!seenKeys.contains('am')) {
      updatedEntries.add(MapEntry('am', amount));
    }
    if (note.isNotEmpty && !seenKeys.contains('tn')) {
      updatedEntries.add(MapEntry('tn', note));
    }
    if (!seenKeys.contains('cu')) {
      updatedEntries.add(const MapEntry('cu', 'INR'));
    }

    final rebuiltQuery = updatedEntries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    return originalUri.replace(query: rebuiltQuery);
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _loadSupportedUpiApps();
    }
  }

  Future<void> _loadSupportedUpiApps() async {
    if (!Platform.isAndroid || isFetchingApps) return;

    setState(() => isFetchingApps = true);
    try {
      final apps = await _upiPay.getInstalledUpiApplications(
        statusType: UpiApplicationDiscoveryAppStatusType.workingWithWarnings,
      );
      if (mounted) {
        setState(() => _supportedUpiApps = apps);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _supportedUpiApps = []);
      }
    } finally {
      if (mounted) {
        setState(() => isFetchingApps = false);
      }
    }
  }

  @override
  void dispose() {
    qrController?.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanning) {
        setState(() => isScanning = true);
        qrController?.pauseCamera();
        _handleScannedQR(scanData.code);
      }
    });
  }

  void _handleScannedQR(String? data) async {
    if (data == null) return;
    scannedQrRaw = data;
    // Parse UPI QR (very basic, for demo)
    Uri? uri;
    try {
      uri = Uri.parse(data);
    } catch (_) {}
    if (uri != null && uri.scheme == 'upi' && uri.host == 'pay') {
      setState(() {
        scannedUpiId = uri?.queryParameters['pa'];
        scannedMerchant = uri?.queryParameters['pn'];
        scannedMerchantCode = uri?.queryParameters['mc'];
        scannedAmount = uri?.queryParameters['am'];
        amountController.text = scannedAmount ?? '';
      });
      Navigator.of(context).pop();
      _showPaymentForm();
    } else {
      // Not a valid UPI QR
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_label('invalidUpiQr'))));
      setState(() => isScanning = false);
      qrController?.resumeCamera();
    }
  }

  void _showQRScanner() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_label('cameraRequired'))));
      return;
    }
    setState(() => isScanning = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.deepPurple,
            borderRadius: 12,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: MediaQuery.of(context).size.width * 0.7,
          ),
        ),
      ),
    ).whenComplete(() {
      qrController?.dispose();
    });
  }

  void _showPaymentForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Text(
                  _label('makePayment'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scannedMerchant ?? _label('merchant'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          scannedUpiId ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _label('amount'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _label('category'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(_categoryLabel(cat)),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedCategory = val ?? 'Food'),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.label_outline,
                    color: Colors.black54,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _label('noteOptional'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: _label('noteHint'),
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_label('enterAmount'))),
                      );
                      return;
                    }
                    if (scannedUpiId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_label('invalidUpiId'))),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _showSupportedUpiAppsSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade200,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _label('payNow'),
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUpiUrl() async {
    Uri uri;
    if (scannedQrRaw != null) {
      uri = _buildUpiUriFromRawQr(
        scannedQrRaw!,
        amount: amountController.text.trim(),
        note: noteController.text.trim(),
      );
    } else {
      uri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': scannedUpiId,
          'pn': scannedMerchant ?? _label('merchant'),
          'tr': 'TXN${DateTime.now().millisecondsSinceEpoch}',
          if (noteController.text.isNotEmpty) 'tn': noteController.text,
          'am': amountController.text,
          'cu': 'INR',
        },
      );
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_label('noUpiApp'))));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_label('failedToLaunch')}: $e')),
        );
    }
  }

  Future<void> _launchViaUpiPay(ApplicationMeta app) async {
    try {
      final response = await _upiPay.initiateTransaction(
        amount: amountController.text.trim(),
        app: app.upiApplication,
        receiverName: scannedMerchant ?? _label('merchant'),
        receiverUpiAddress: scannedUpiId!,
        transactionRef: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      if (!mounted) return;

      if (response.status == UpiTransactionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.rawResponse?.isNotEmpty == true
                  ? 'Payment failed: ${response.rawResponse}'
                  : _label('paymentRejected'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_label('failedToLaunch')} ${app.upiApplication.appName}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showSupportedUpiAppsSheet() async {
    if (!Platform.isAndroid || !_isPersonalUpiQr) {
      await _launchUpiUrl();
      return;
    }

    if (_supportedUpiApps.isEmpty && !isFetchingApps) {
      await _loadSupportedUpiApps();
    }

    if (!mounted) return;

    if (_supportedUpiApps.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_label('upiPersonalBlocked'))));
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                _label('chooseUpiApp'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._supportedUpiApps.map(
              (app) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: app.iconImage(44),
                  ),
                ),
                title: Text(app.upiApplication.appName),
                onTap: () async {
                  Navigator.pop(context);
                  await _launchViaUpiPay(app);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.language,
      builder: (context, language, child) {
        final strings = AppStrings.current;
        final double spent = 42322.50;
        final double budget = 40000.00;
        final double overspent = spent - budget;
        final List<Map<String, dynamic>> categories = [
          {
            'name': 'Food',
            'amount': 14812.87,
            'percent': 35,
            'color': Colors.orange,
          },
          {
            'name': 'Travel',
            'amount': 10580.62,
            'percent': 25,
            'color': Colors.blue,
          },
          {
            'name': 'Shopping',
            'amount': 8464.50,
            'percent': 20,
            'color': Colors.purple,
          },
          {
            'name': 'Other',
            'amount': 8464.50,
            'percent': 20,
            'color': Colors.green,
          },
        ];
        final List<Map<String, dynamic>> transactions = _filteredTransactions
            .take(5)
            .toList();
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.black),
                onPressed: () async {
                  await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spent summary card
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.t('spentThisMonth'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    strings.t('summary'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${spent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: spent / budget > 1 ? 1 : spent / budget,
                                backgroundColor: const Color(0xFFE9E9E9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.deepPurple,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            if (spent > budget)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${strings.t('budget')}: ₹${budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '${strings.t('overspent')}: ₹${overspent.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: spent > budget
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (spent > budget) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFEAEA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    strings.t('budgetExceeded'),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit, color: Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Spending Categories
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('spendingCategories'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CustomPaint(
                                    painter: _DonutChartPainter(categories),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      strings.t('totalSpent'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '₹42,322',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...categories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: cat['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _categoryLabel(cat['name'] as String),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##0.00').format(cat['amount'] as num)}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${cat['percent']}%',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.t('recentTransactions'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsScreen(
                                allTransactions: _filteredTransactions,
                              ),
                            ),
                          );
                        },
                        child: Text(strings.t('seeAll')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('Income'),
                        _buildFilterChip('Expense'),
                        _buildFilterChip('Food'),
                        _buildFilterChip('Shopping'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...transactions.map(
                    (tx) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (tx['color'] as Color?)?.withOpacity(
                            0.15,
                          ),
                          child: Icon(
                            tx['icon'] as IconData?,
                            color: tx['color'] as Color?,
                          ),
                        ),
                        title: Text(
                          tx['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${tx['subtitle']}\n${tx['method']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${(tx['amount'] as num?) != null && (tx['amount'] as num) > 0 ? '+' : ''}₹${(tx['amount'] as num?)?.abs().toStringAsFixed(2) ?? ''}',
                          style: TextStyle(
                            color:
                                ((tx['amount'] as num?) != null &&
                                    (tx['amount'] as num) > 0)
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: _showQRScanner,
            backgroundColor: Colors.deepPurple,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: Colors.white.withValues(alpha: 0.96),
            surfaceTintColor: Colors.transparent,
            elevation: 10,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.home_filled,
                      isActive: true,
                      onTap: () {},
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.forum_outlined,
                      isActive: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const FinanceAdviserChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 72),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.person_outline_rounded,
                      isActive: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(_categoryLabel(label)),
        selected: selected,
        selectedColor: Colors.deepPurple.withOpacity(0.15),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.deepPurple : Colors.black54,
        ),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedFilter = label);
          }
        },
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.deepPurple : const Color(0xFF9A9AA4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.deepPurple.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List categories;
  _DonutChartPainter(this.categories);

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -3.14 / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final total = categories.fold<int>(
      0,
      (sum, cat) => sum + (cat['percent'] as int),
    );
    for (var cat in categories) {
      final sweepAngle = (cat['percent'] / total) * 3.14 * 2;
      final paint = Paint()
        ..color = cat['color']
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
