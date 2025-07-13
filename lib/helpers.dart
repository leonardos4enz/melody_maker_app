// helpers.dart
// Utilidades de conversión de notas y duraciones

/// Mapa A-B -> nombre en español
const noteMap = <String, String>{
  'C': 'Do',
  'Db': 'Do#',
  'D': 'Re',
  'Eb': 'Re#',
  'E': 'Mi',
  'F': 'Fa',
  'Gb': 'Fa#',
  'G': 'Sol',
  'Ab': 'Sol#',
  'A': 'La',
  'Bb': 'La#',
  'B': 'Si',
};

/// Duraciones aceptadas (igual que la versión web)
const durations = ['16n', '8n', '4n', '4n.', '2n', '2n.'];

/// Convierte una duración (p.e. "4n.") a segundos
double durToSeconds(String d) {
  final dotted = d.endsWith('.');
  final base = dotted ? d.substring(0, d.length - 1) : d;
  final double sec = switch (base) {
    '16n' => 0.125,
    '8n' => 0.25,
    '4n' => 0.5,
    '2n' => 1.0,
    _ => 0.5,
  };
  return dotted ? sec * 1.5 : sec;
}

/// Convierte una nota (“C4”, “Ab5”…) a número MIDI (0-127)
int noteToMidi(String note) {
  final rx = RegExp(r'^([A-G][b#]?)(\d)$').firstMatch(note)!;
  final pc = rx.group(1)!;
  final oct = int.parse(rx.group(2)!);

  const semitoneOf = {
    'C': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11,
  };

  return (oct + 1) * 12 + semitoneOf[pc]!;
}
