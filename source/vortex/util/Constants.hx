package vortex.util;

import lime.app.Application;
import flixel.util.FlxColor;
class Constants {
  public static var VERSION(get, never): String;

  static function get_VERSION(): String {
    return 'v${Application.current.meta.get('version')}';
  }

  public static final TITLE: String = "FunkinVortex";

  public static var GENERATED_BY(get, never): String;

  static function get_GENERATED_BY(): String {
    return '${Constants.TITLE} - ${Constants.VERSION}';
  }

  public static final DEFAULT_NOTE_STYLE:String = "funkin";

  public static final EXT_DATA:String = "json";
  public static final EXT_SOUND:String = "ogg";

  public static final DEFAULT_VARIATION: String = "default";
  public static final DEFAULT_CHARACTER: String = "bf";
  public static final DEFAULT_OPPONENT: String = "dad";
  public static final DEFAULT_BPM: Float = 100.0;
  public static final DEFAULT_TIME_SIGNATURE_NUM = 4;
  public static final DEFAULT_TIME_SIGNATURE_DEN = 4;
  public static final STEPS_PER_BEAT: Int = 4;
  // a helper for quantization
  public static final ROWS_PER_BEAT: Int = 48;
  public static final ROWS_PER_STEP: Int = Std.int(ROWS_PER_BEAT / STEPS_PER_BEAT);
  public static final ROWS_PER_MEASURE: Int = ROWS_PER_BEAT * 4;
  public static final BEATS_PER_MEASURE: Int = 4;
  public static final MS_PER_SEC: Int = 1000;
  public static final SECS_PER_MINUTE: Int = 60;
  // ??????
  public static final PIXELS_PER_MS: Float = 0.45;

    /**
   * The base colors used by notes.
   */
  public static var COLOR_NOTES:Array<FlxColor> = [
    0xFFFF22AA, // left (0)
    0xFF00EEFF, // down (1)
    0xFF00CC00, // up (2)
    0xFFCC1111 // right (3)
  ];
  public static final QUANT_ARRAY: Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 192];

  public static final DANCE_SINGLE: String = "dance-single";
  public static final DANCE_DOUBLE: String = "dance-double";
  public static final DANCE_SOLO: String = "dance-solo";
  public static final DANCE_COUPLE: String = "dance-couple";
  public static final DANCE_THREEPANEL: String = "dance-threepanel";
  public static final DANCE_ROUTINE: String = "dance-routine";

  public static final PUMP_SINGLE: String = "pump-single";
  public static final PUMP_HALFDOUBLE: String = "pump-halfdouble";
  public static final PUMP_DOUBLE: String = "pump-double";
  public static final PUMP_COUPLE: String = "pump-couple";
  public static final PUMP_ROUTINE: String = "pump-routine";
}

