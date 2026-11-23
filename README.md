# Modern Quran Player 3.2 — KDE Plasma 6

Based on Quran Player by muhyo (Apache-2.0).

- Popup: Listen / Library panel on the left, player on the right (panel can be hidden).
- Configuration dialog: one "Playback" page (Listen + Library + defaults) and "Popup".
  The dialog is a separate QML context, so it controls the live player through
  Plasmoid.configuration (`cmd` key for commands; reciters/library/now-playing mirrored back).
- Panel icon shows an animated equalizer badge while playing.
