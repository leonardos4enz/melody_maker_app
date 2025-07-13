# Melody Studio 🎹

> **Diseña, escucha y exporta** tus propias melodías desde el teléfono o el navegador,  
> usando un teclado virtual y una línea de tiempo interactiva.

![preview](https://github.com/leonardos4enz/melody_maker_app/blob/main/assets/melody_maker_app.jpeg)

---

## ✨ Características

| Módulo                | Descripción                                                                                           |
|-----------------------|--------------------------------------------------------------------------------------------------------|
| **Selector de valor** | `ChoiceChip` para cambiar la duración _(16n · 8n · 4n · 4n. · 2n · 2n.)_                              |
| **Teclado en grid**   | 24 notas (C4 – B5) en cuadrícula **4 × N**<br>• **Tap ➜ pre-escucha**<br>• **＋ ➜ añadir a la pista** |
| **Timeline**          | Pista siempre visible en la parte inferior; chips editables y eliminables                             |
| **Instrumentos GM**   | Selector modal con instrumentos General-MIDI (Flauta, Piano, Violín, Saxofón, etc.)                    |
| **Sonido realista**   | Motor MIDI basado en SoundFont **FluidR3 GM** + `flutter_midi_pro`                                     |
| **Material You**      | Interfaz Google Fonts + esquema de color dinámico                                                     |
| **Plataformas**       | Android • iOS (beta) • Web • Desktop (Flutter 3.10 +)                                                  |

---

## 🚀 Stack técnico

- **Flutter 3.10 +** (`useMaterial3: true`)
- **google_fonts** – tipografía *Inter*
- **flutter_midi_pro** – reproducción MIDI
- **path_provider** – manejo de archivos temporales
- **Dart 3 null-safe**

---

## 📦 Instalación local

```bash
git clone https://github.com/leonardos4enz/melody_maker_app
cd melody_maker_app
flutter pub get
flutter run        # o flutter run -d chrome
