import 'dart:async';

import 'package:flutter/material.dart';

import 'settings_page.dart';
import 'telemetry.dart';

class TelemetryPage extends StatefulWidget {
  const TelemetryPage({super.key});

  @override
  State<TelemetryPage> createState() => _TelemetryPageState();
}

class _TelemetryPageState extends State<TelemetryPage> {
  final List<NativeSignal> _signals = [];
  int _pending = 0;

  @override
  void initState() {
    super.initState();

    Telemetry.nativeSignals().listen((s) {
      if (!mounted) return;
      setState(() => _signals.add(s));
    });

    Telemetry.installCallbackHandler((call) async {
      switch (call.method) {
        case 'currentUserId':
          return 'u-1042';
        case 'onNativeEvent':
          final e = TelemetryEvent.fromMap(
              (call.arguments as Map).cast<Object?, Object?>());
          Telemetry.recent.add(e);
          if (mounted) setState(() {});
          return null;
      }
      return null;
    });

    BackgroundUploader.instance.start();
    _refresh();
  }

  Future<void> _refresh() async {
    final c = await EventStore.instance.pendingCount();
    if (mounted) setState(() => _pending = c);
  }

  @override
  Widget build(BuildContext context) {
    final tail = Telemetry.recent.reversed.take(50).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () async {
              await BackgroundUploader.uploadOnce();
              await _refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Pending: $_pending'),
            subtitle: Text('Signals this session: ${_signals.length} · '
                'Events in memory: ${Telemetry.recent.length}'),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: tail.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                title: Text(tail[i].name),
                trailing: Text('${tail[i].atUptimeMs} ms'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
