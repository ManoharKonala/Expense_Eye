import 'package:flutter/material.dart';
import '../app_language.dart';

class TransactionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allTransactions;
  const TransactionsScreen({super.key, required this.allTransactions});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.language,
      builder: (context, language, child) {
        final strings = AppStrings.current;
        int totalPages = max(
          1,
          (widget.allTransactions.length / _itemsPerPage).ceil(),
        );
        int startIndex = (_currentPage - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > widget.allTransactions.length) {
          endIndex = widget.allTransactions.length;
        }

        if (startIndex >= widget.allTransactions.length &&
            widget.allTransactions.isNotEmpty) {
          startIndex = 0;
          endIndex = widget.allTransactions.length < _itemsPerPage
              ? widget.allTransactions.length
              : _itemsPerPage;
          _currentPage = 1;
        }

        List<Map<String, dynamic>> currentTransactions =
            widget.allTransactions.isEmpty
            ? []
            : widget.allTransactions.sublist(startIndex, endIndex);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.t('allTransactions'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
          ),
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(
            children: [
              Expanded(
                child: currentTransactions.isEmpty
                    ? Center(child: Text(strings.t('noTransactions')))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = currentTransactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: (tx['color'] as Color?)
                                    ?.withOpacity(0.15),
                                child: Icon(
                                  tx['icon'] as IconData?,
                                  color: tx['color'] as Color?,
                                ),
                              ),
                              title: Text(
                                tx['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${tx['subtitle']}\n${tx['method']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                '${(tx['amount'] as num) > 0 ? '+' : ''}₹${(tx['amount'] as num).abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: (tx['amount'] as num) > 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Pagination Controls
              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                          color: _currentPage > 1
                              ? Colors.deepPurple
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${strings.t('page')} $_currentPage ${strings.t('of')} $totalPages',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                          color: _currentPage < totalPages
                              ? Colors.deepPurple
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  int max(int a, int b) => a > b ? a : b;
}
