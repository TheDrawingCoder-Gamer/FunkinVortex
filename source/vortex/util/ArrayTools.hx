package vortex.util;

class ArrayTools {

  /**
   * Create a new array with all elements of the given array, to prevent modifying the original.
   */
  public static function clone<T>(array:Array<T>):Array<T>
  {
    return [for (element in array) element];
  }

  /**
   * Create a new array with clones of all elements of the given array, to prevent modifying the original.
   */
  public static function deepClone<T, U:ICloneable<T>>(array:Array<U>):Array<T>
  {
    return [for (element in array) element.clone()];
  }
}
