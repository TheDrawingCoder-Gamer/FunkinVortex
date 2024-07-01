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
}
