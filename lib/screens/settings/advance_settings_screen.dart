import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/equalizer_service.dart';
import 'widgets/color_wheel.dart';

/// F2: Advance Settings — Custom Equalizer + Custom Theme.
/// Opens from the new drawer row added in File 19.
class AdvanceSettingsScreen extends StatefulWidget {
  const AdvanceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdvanceSettingsScreen> createState() => _AdvanceSettingsScreenState();
}

class _AdvanceSettingsScreenState extends State<AdvanceSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Leaving the screen without pressing "Set" on the Custom Theme tab
    // must not persist anything — revert any live preview back to the
    // previously saved theme.
    context.read<ThemeProvider>().cancelPreview();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(
          'Advance Settings',
          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        iconTheme: IconThemeData(color: t.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: t.accent,
          unselectedLabelColor: t.textSecondary,
          indicatorColor: t.accent,
          tabs: const [
            Tab(text: 'Custom Equalizer'),
            Tab(text: 'Custom Theme'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CustomEqualizerTab(),
          _CustomThemeTab(),
        ],
      ),
    );
  }
}

// =========================================================
// a) Custom Equalizer
// =========================================================

class _CustomEqualizerTab extends StatefulWidget {
  const _CustomEqualizerTab();

  @override
  State<_CustomEqualizerTab> createState() => _CustomEqualizerTabState();
}

class _CustomEqualizerTabState extends State<_CustomEqualizerTab> {
  final _eqService = EqualizerService();
  List<EqBandInfo> _bands = [];
  double _bassBoost = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bands = await _eqService.getCustomBands();
    if (!mounted) return;
    setState(() {
      _bands = bands;
      _loading = false;
    });
  }

  Future<void> _reset() async {
    final themeProvider = context.read<ThemeProvider>();
    await _eqService.resetCustomEq(themeProvider.eqPreset);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Equalizer reset to default.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.accent));
    }

    if (_bands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Custom equalizer isn\'t supported on this device/platform.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '5-BAND EQUALIZER',
            style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _bands.map((band) {
                return _BandSlider(
                  band: band,
                  accent: t.accent,
                  textColor: t.textPrimary,
                  onChanged: (gain) {
                    setState(() {
                      final idx = _bands.indexWhere((b) => b.bandIndex == band.bandIndex);
                      _bands[idx] = EqBandInfo(
                        bandIndex: band.bandIndex,
                        centerFrequencyHz: band.centerFrequencyHz,
                        gainDb: gain,
                        minDb: band.minDb,
                        maxDb: band.maxDb,
                      );
                    });
                    _eqService.setCustomBandGain(band.bandIndex, gain);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'BASS BOOST',
            style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          Slider(
            value: _bassBoost,
            min: 0,
            max: 6,
            activeColor: t.accent,
            inactiveColor: t.textPrimary.withOpacity(0.2),
            onChanged: (v) {
              setState(() => _bassBoost = v);
              _eqService.setBassBoost(v);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.textPrimary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Reset to Default', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  final EqBandInfo band;
  final Color accent;
  final Color textColor;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.band,
    required this.accent,
    required this.textColor,
    required this.onChanged,
  });

  String get _label {
    final hz = band.centerFrequencyHz;
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k';
    return hz.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: band.gainDb.clamp(band.minDb, band.maxDb),
              min: band.minDb,
              max: band.maxDb,
              activeColor: accent,
              inactiveColor: textColor.withOpacity(0.2),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('$_label Hz', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }
}

// =========================================================
// b) Custom Theme
// =========================================================

class _CustomThemeTab extends StatefulWidget {
  const _CustomThemeTab();

  @override
  State<_CustomThemeTab> createState() => _CustomThemeTabState();
}

class _CustomThemeTabState extends State<_CustomThemeTab> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    final current = context.read<ThemeProvider>().theme.accent;
    _hsv = HSVColor.fromColor(current);
  }

  void _updateFromWheel(HSVColor hsv) {
    setState(() => _hsv = hsv);
    // Live real-time preview, before saving.
    context.read<ThemeProvider>().previewCustomTheme(_hsv.toColor());
  }

  void _updateShade(double value) {
    final updated = _hsv.withValue(value);
    setState(() => _hsv = updated);
    context.read<ThemeProvider>().previewCustomTheme(updated.toColor());
  }

  Future<void> _set() async {
    await context.read<ThemeProvider>().commitCustomTheme(_hsv.toColor());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme saved.')),
    );
  }

  Future<void> _reset() async {
    await context.read<ThemeProvider>().resetToDefaultTheme();
    if (!mounted) return;
    final defaultAccent = context.read<ThemeProvider>().theme.accent;
    setState(() => _hsv = HSVColor.fromColor(defaultAccent));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            'PICK YOUR COLOR',
            style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          ColorWheel(
            hue: _hsv.hue,
            saturation: _hsv.saturation,
            value: _hsv.value,
            onChanged: _updateFromWheel,
          ),
          const SizedBox(height: 24),
          Text(
            'SHADE',
            style: TextStyle(color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          Slider(
            value: _hsv.value,
            min: 0.15,
            max: 1.0,
            activeColor: _hsv.toColor(),
            onChanged: _updateShade,
          ),
          const SizedBox(height: 12),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.textPrimary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text('Live preview', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: t.textPrimary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Reset', style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _set,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
