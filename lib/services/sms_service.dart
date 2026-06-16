import 'dart:io';

import 'package:flutter_send_sms/flutter_send_sms.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  Future<void> sendEmergencySmsToContacts({
    required List<Map<String, dynamic>> contacts,
    required String message,
  }) async {
    if (!Platform.isAndroid) {
      throw Exception('Direct SMS sending is currently supported only on Android');
    }

    final smsPermission = await Permission.sms.status;

    if (!smsPermission.isGranted) {
      final requestedPermission = await Permission.sms.request();

      if (!requestedPermission.isGranted) {
        throw Exception('SMS permission denied');
      }
    }

    for (final contact in contacts) {
      final phoneNumber = contact['phone_number']?.toString();

      if (phoneNumber == null || phoneNumber.trim().isEmpty) {
        continue;
      }

      print('SMS STEP: sending SMS to $phoneNumber');

      await FlutterSendSms.sendSms(
        phoneNumber,
        message,
      );

      print('SMS STEP: SMS sent to $phoneNumber');
    }
  }
}
