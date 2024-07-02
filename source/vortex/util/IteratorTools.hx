package vortex.util;

class IteratorUtils {
  public static function array<T>(iterator:Iterator<T>):Array<T>
  {
    return [for (i in iterator) i];
  }
}
