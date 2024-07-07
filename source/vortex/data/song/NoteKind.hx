package vortex.data.song;

// The kind of note to display : )
// TODO: hardcoded
enum abstract NoteKind(String) from String to String {
  final NORMAL = "normal";
  final DIAGONAL = "diagonal";
  final CENTER = "center";
  final BAR = "bar";
  final CIRCLE = "circle";
}
