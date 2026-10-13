import 'package:flutter/material.dart';

import 'telemetry_page.dart';

void main() {
  runApp(const TelemetryApp());
}

class TelemetryApp extends StatelessWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Telemetry',
        theme: ThemeData(useMaterial3: true),
        home: const TelemetryPage(),
      );
}
