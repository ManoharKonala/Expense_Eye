// Temporary helper to print the type and fields of the result from EasyUpiPaymentPlatform.instance.startPayment
import 'package:easy_upi_payment/easy_upi_payment.dart';
import 'dart:async';

void main() async {
  // This is a placeholder. In your app, the result of startPayment is likely a Map or a custom class.
  // Print the runtimeType and fields for debugging.
  final res = await EasyUpiPaymentPlatform.instance.startPayment(
    EasyUpiPaymentModel(
      payeeVpa: 'test@upi',
      payeeName: 'Test',
      amount: 1.0,
      description: 'Test',
    ),
  );
  print('Result type: \\${res.runtimeType}');
  print('Result: \\$res');
  if (res is Map) {
    print('Keys: \\${res.keys}');
  }
}
