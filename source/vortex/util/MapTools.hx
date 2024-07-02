package vortex.util;

class MapTools {
  public static function clone<K, T>(map: Map<K, T>): Map<K, T> {
    return map.copy();
  }
  public static function size<K, T>(map: Map<K, T>): Int {
    return map.keys().array().length;
  }
}
