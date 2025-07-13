// lib/main.dart – Melody Studio (versión pulida y sin errores)

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers.dart';
import 'model.dart';

void main() => runApp(const MelodyApp());

class MelodyApp extends StatelessWidget {
  const MelodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3A6AFB));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melody Studio',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const MelodyMaker(),
    );
  }
}

class MelodyMaker extends StatefulWidget {
  const MelodyMaker({super.key});
  @override
  State<MelodyMaker> createState() => _MelodyMakerState();
}

class _MelodyMakerState extends State<MelodyMaker>
    with SingleTickerProviderStateMixin {
  // ───────── AUDIO ─────────
  final _midi = MidiPro();
  int? _sfId;
  final _channel = 0;
  int _program = 73;

  // ───────── STATE ─────────
  bool _loading = true;
  bool _isPlaying = false;
  int _playingIdx = -1;
  String _currentDur = '4n';
  final _melody = <MelodyEvent>[];

  late final AnimationController _fabCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  static const _instruments = {
    'Flauta': 73,
    'Piano': 0,
    'Violín': 40,
    'Clarinete': 71,
    'Guitarra': 24,
    'Trompeta': 56,
    'Saxofón': 65,
  };

  @override
  void initState() {
    super.initState();
    _initSoundFont();
  }

  Future<void> _initSoundFont() async {
    final bytes = await rootBundle.load('assets/soundfonts/FluidR3_GM.sf2');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/FluidR3_GM.sf2');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    _sfId =
        await _midi.loadSoundfont(path: file.path, bank: 0, program: _program);
    setState(() => _loading = false);
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('🎼 Melody Studio'),
        backgroundColor: scheme.surface.withOpacity(.9),
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: _isPlaying ? 'Detener' : 'Reproducir',
        onPressed:
            _melody.isEmpty ? null : (_isPlaying ? _stopPlayback : _startPlayback),
        child: AnimatedIcon(icon: AnimatedIcons.play_pause, progress: _fabCtrl),
      ),
      bottomNavigationBar: _BottomBar(
        onInstrument: _showInstrumentSheet,
        onClear: _melody.isEmpty ? null : () => setState(_melody.clear),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primaryContainer, scheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.list(children: [
                    _durationSelector(),
                    const SizedBox(height: 20),
                    _pianoCard(),
                    const SizedBox(height: 24),
                    _sequenceCard(),
                    const SizedBox(height: 90),
                  ]),
                )
              ]),
      ),
    );
  }

  // — Duración + silencio
  Widget _durationSelector() => Row(children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            children: durations
                .map((d) => ChoiceChip(
                      label: Text(d),
                      selected: _currentDur == d,
                      onSelected: (_) => setState(() => _currentDur = d),
                    ))
                .toList(),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: _addRest,
          icon: const Icon(Icons.music_off),
          label: const Text('Silencio'),
        )
      ]);

  // — Piano
  Widget _pianoCard() => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Piano virtual', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _piano(),
          ],
        ),
      );

  Widget _piano() {
    const notes = [
      'C4','Db4','D4','Eb4','E4','F4','Gb4','G4','Ab4','A4','Bb4','B4',
      'C5','Db5','D5','Eb5','E5','F5','Gb5','G5','Ab5','A5','Bb5','B5',
    ];
    final blacks = {'Db','Eb','Gb','Ab','Bb'};

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: notes.length,
        itemBuilder: (context, i) {
          final n = notes[i];
          final base = n.substring(0, n.length - 1);
          final oct = n.substring(n.length - 1);
          final isBlack = blacks.contains(base);
          final bg = isBlack ? Colors.grey.shade900 : Colors.white70;
          final fg = isBlack ? Colors.white : Colors.black87;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _preview(n),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          child: Text('${noteMap[base]}$oct',
                              style: TextStyle(
                                  color: fg, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(34, 34),
                          ),
                          icon: const Icon(Icons.add),
                          onPressed: () => _addNote(n),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // — Secuencia
  Widget _sequenceCard() => _GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Secuencia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _melody.isEmpty
              ? Text('Añade notas o silencios…',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outlineVariant))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_melody.length, _chip),
                ),
        ]),
      );

  Widget _chip(int i) {
    final ev = _melody[i];
    final playing = i == _playingIdx;
    final base =
        ev.type == EventType.note ? ev.note!.replaceAll(RegExp(r'\d'), '') : '';
    final label = ev.type == EventType.note ? noteMap[base]! : '𝄻';
    return FilterChip(
      selected: playing,
      selectedColor: Colors.orange,
      label: Text('$label  •  ${ev.dur}',
          style: const TextStyle(color: Colors.white)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      onDeleted: () => _removeEvent(i),
      onSelected: (_) => _cycleDuration(i),
    );
  }

  // ───────── LÓGICA ─────────
  void _addNote(String n) =>
      setState(() => _melody.add(MelodyEvent.note(n, _currentDur)));
  void _addRest() => setState(() => _melody.add(MelodyEvent.rest(_currentDur)));
  void _removeEvent(int i) => setState(() => _melody.removeAt(i));

  void _cycleDuration(int i) {
    final ev = _melody[i];
    final idx = durations.indexOf(ev.dur);
    final next = durations[(idx + 1) % durations.length];
    setState(() => _melody[i] = ev.type == EventType.note
        ? MelodyEvent.note(ev.note!, next)
        : MelodyEvent.rest(next));
  }

  Future<void> _preview(String n) async {
    final midi = noteToMidi(n);
    await _midi.playNote(
        sfId: _sfId!, channel: _channel, key: midi, velocity: 110);
    await Future.delayed(const Duration(milliseconds: 250));
    await _midi.stopNote(sfId: _sfId!, channel: _channel, key: midi);
  }

  Future<void> _changeInstrument(int p) async {
    setState(() => _program = p);
    await _midi.selectInstrument(
        sfId: _sfId!, channel: _channel, bank: 0, program: p);
  }

  Future<void> _startPlayback() async {
    setState(() => _isPlaying = true);
    _fabCtrl.forward();
    for (var i = 0; i < _melody.length; i++) {
      final ev = _melody[i];
      setState(() => _playingIdx = i);

      if (ev.type == EventType.note) {
        final midi = noteToMidi(ev.note!);
        await _midi.playNote(
            sfId: _sfId!, channel: _channel, key: midi, velocity: 127);
      }
      await Future.delayed(
          Duration(milliseconds: (durToSeconds(ev.dur) * 1000).round()));
      if (ev.type == EventType.note) {
        final midi = noteToMidi(ev.note!);
        await _midi.stopNote(sfId: _sfId!, channel: _channel, key: midi);
      }
    }
    _stopPlayback();
  }

  Future<void> _stopPlayback() async {
    await _midi.stopNote(sfId: _sfId!, channel: _channel, key: 0);
    _fabCtrl.reverse();
    setState(() {
      _isPlaying = false;
      _playingIdx = -1;
    });
  }

  // Instrumentos
  void _showInstrumentSheet() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: _instruments.entries
            .map((e) => ListTile(
                  leading: Icon(Icons.music_note,
                      color:
                          e.value == _program ? scheme.primary : scheme.outline),
                  title: Text(e.key),
                  trailing:
                      e.value == _program ? const Icon(Icons.check) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _changeInstrument(e.value);
                  },
                ))
            .toList(),
      ),
    );
  }
}

// ────── Glass card helper ──────
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant, width: .8),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
}

// ────── Bottom bar ──────
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onInstrument, required this.onClear});
  final VoidCallback onInstrument;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => BottomAppBar(
        shape: const CircularNotchedRectangle(),
        elevation: 6,
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            IconButton(
              tooltip: 'Instrumento',
              icon: const Icon(Icons.piano),
              onPressed: onInstrument,
            ),
            IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onClear,
            ),
            const Spacer(),
          ]),
        ),
      );
}
