// model.dart
// Objeto que representa cada evento (nota o silencio) de la melodía

enum EventType { note, rest }

class MelodyEvent {
  const MelodyEvent.note(this.note, this.dur) : type = EventType.note;
  const MelodyEvent.rest(this.dur) : note = null, type = EventType.rest;

  final EventType type;
  final String? note; // "C4", "G#5", etc.
  final String dur; // "4n", "2n.", …

  // ---- serialización a JSON ----
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'note': note,
    'dur': dur,
  };

  static MelodyEvent fromJson(Map m) => m['type'] == 'note'
      ? MelodyEvent.note(m['note'], m['dur'])
      : MelodyEvent.rest(m['dur']);
}
