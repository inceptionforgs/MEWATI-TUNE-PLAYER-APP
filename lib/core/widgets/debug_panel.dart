// File: lib/core/widgets/debug_panel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_themes.dart';
import '../../providers/theme_provider.dart';
import '../../services/debug_log_service.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({Key? key}) : super(key: key);

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final DebugLogService _logService = DebugLogService();
  Offset _position = const Offset(20, 80);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: _expanded ? _buildExpandedPanel(t) : _buildCollapsedButton(t),
      ),
    );
  }

  Widget _buildCollapsedButton(AppThemeData t) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: t.surface,
      onPressed: () => setState(() => _expanded = true),
      child: Icon(Icons.bug_report, color: t.textPrimary, size: 20),
    );
  }

  Widget _buildExpandedPanel(AppThemeData t) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: t.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.textPrimary.withOpacity(0.24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: t.textPrimary.withOpacity(0.24)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'DEBUG LOGS',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, color: t.textPrimary, size: 18),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _logService.getAllLogsAsString()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logs copied to clipboard')),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: t.textPrimary, size: 18),
                  onPressed: () {
                    _logService.clear();
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: t.textPrimary, size: 18),
                  onPressed: () => setState(() => _expanded = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DebugLog>(
              stream: _logService.logStream,
              builder: (context, snapshot) {
                final logs = _logService.logs;
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    Color color;
                    switch (log.level) {
                      case LogLevel.info:
                        color = t.textPrimary.withOpacity(0.7);
                        break;
                      case LogLevel.warning:
                        color = Colors.orangeAccent;
                        break;
                      case LogLevel.error:
                        color = Colors.redAccent;
                        break;
                    }
                    final time =
                        '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        '[$time] ${log.message}',
                        style: TextStyle(color: color, fontSize: 11),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
