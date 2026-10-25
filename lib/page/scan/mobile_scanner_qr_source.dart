import 'dart:async';

import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobileScannerQrSource implements QrScanSource {
  final StreamController<String> _codes = StreamController<String>.broadcast();

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Widget buildView() {
    return MobileScanner(
      onDetect: (BarcodeCapture capture) {
        for (final Barcode barcode in capture.barcodes) {
          final String? raw = barcode.rawValue;
          if (raw != null && !_codes.isClosed) {
            _codes.add(raw);
          }
        }
      },
    );
  }
}
