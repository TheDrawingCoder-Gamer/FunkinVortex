package vortex.data.song;

enum abstract Gamemode(String) from String to String {
  var DANCE_SINGLE = "dance-single";
  var DANCE_DOUBLE = "dance-double";
  var DANCE_SOLO = "dance-solo";
  var DANCE_COUPLE = "dance-couple";
  var DANCE_THREEPANEL = "dance-threepanel";
  var DANCE_ROUTINE = "dance-routine";

  var PUMP_SINGLE = "pump-single";
  var PUMP_HALFDOUBLE = "pump-halfdouble";
  var PUMP_DOUBLE = "pump-double";
  var PUMP_COUPLE = "pump-couple";
  var PUMP_ROUTINE = "pump-routine";

  public var noteCount(get, never): Int;

  public function get_noteCount(): Int {
    return switch (this) {
      case DANCE_SINGLE: 4;
      case DANCE_DOUBLE | DANCE_COUPLE | DANCE_ROUTINE: 8;
      case DANCE_SOLO: 6;
      case DANCE_THREEPANEL: 3;
      case PUMP_SINGLE: 5;
      case PUMP_DOUBLE | PUMP_COUPLE | PUMP_ROUTINE: 10;
      case PUMP_HALFDOUBLE: 6;
      default: 4;
    };
  }
}
