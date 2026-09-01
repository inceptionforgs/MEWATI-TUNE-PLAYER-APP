import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // NOTE: kDebugMode gate removed on purpose so this panel renders in
    // every build, including release. It will be visible to end users.
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: _expanded ? _buildExpandedPanel() : _buildCollapsedButton(),
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.black87,
      onPressed: () => setState(() => _expanded = true),
      child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
    );
  }

  Widget _buildExpandedPanel() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white24),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'DEBUG LOGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
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
                  icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                  onPressed: () {
                    _logService.clear();
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
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
                        color = Colors.white70;
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
