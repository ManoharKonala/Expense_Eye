import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_language.dart';

class UpiPaymentButton extends StatefulWidget {
  final String receiverUpi;
  final String receiverName;
  final String amount;
  final String note;

  const UpiPaymentButton({
    super.key,
    required this.receiverUpi,
    required this.receiverName,
    required this.amount,
    required this.note,
  });

  @override
  State<UpiPaymentButton> createState() => _UpiPaymentButtonState();
}

class _UpiPaymentButtonState extends State<UpiPaymentButton> {
  bool _loading = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final uri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': widget.receiverUpi,
          'pn': widget.receiverName,
          'tr': 'TXN${DateTime.now().millisecondsSinceEpoch}',
          if (widget.note.isNotEmpty) 'tn': widget.note,
          'am': widget.amount,
        },
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.current.t('noUpiApp'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ElevatedButton.icon(
      icon: const Icon(Icons.payment),
      label: Text(AppStrings.current.t('payWithUpi')),
      onPressed: _pay,
    );
  }
}
