package vortex.util;

import lime.app.Application;
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

  public static final DEFAULT_VARIATION: String = "default";
  public static final DEFAULT_BPM: Float = 100.0;
  public static final DEFAULT_TIME_SIGNATURE_NUM = 4;
  public static final DEFAULT_TIME_SIGNATURE_DEN = 4;
  public static final STEPS_PER_BEAT: Int = 4;
  public static final MS_PER_SEC: Int = 1000;
  public static final SECS_PER_MINUTE: Int = 60;
}
