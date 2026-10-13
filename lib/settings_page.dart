import 'package:flutter/material.dart';

import 'telemetry.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _verbose = false;

  @override
  void initState() {
    super.initState();
    // Settings needs to answer native's diagnostics probe while it is open.
    Telemetry.installCallbackHandler((call) async {
      if (call.method == 'diagnosticsLevel') return _verbose ? 2 : 0;
      return null;
    });
  }

  @override
  void dispose() {
    Telemetry.removeCallbackHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Verbose diagnostics'),
        value: _verbose,
        onChanged: (v) => setState(() => _verbose = v),
      ),
    );
  }
}
