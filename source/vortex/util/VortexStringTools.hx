package vortex.util;


class VortexStringTools {
  public static final FIRSTH: Int = 37;
  public static final A: Int = 54059;
  public static final B: Int = 76963;
  public static final C: Int = 86969;

  // https://stackoverflow.com/a/8317622
  public static function hashCode(str: String): Int {
    var h: Int = FIRSTH;
    for (i in 0...str.length) {
      var c = str.charCodeAt(i);
      // freaky deaky 
      h = (h * A) ^ (c * B);
    }
    return h;
  }
}
