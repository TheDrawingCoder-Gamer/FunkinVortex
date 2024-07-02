package vortex.util;

class ArraySortTools {
    /**
   * Sorts the input array using the insertion sort algorithm.
   * Stable and is very fast on nearly-sorted arrays,
   * but is inefficient `O(n^2)` in "worst-case" situations.
   *
   * @param input The array to sort in-place.
   * @param compare The comparison function to use.
   */
  public static function insertionSort<T>(input:Array<T>, compare:CompareFunction<T>):Void
  {
    if (input == null || input.length <= 1) return;
    if (compare == null) throw 'No comparison function provided.';

    // Iterate through the array, starting at the second element.
    for (i in 1...input.length)
    {
      // Store the current element.
      var current:T = input[i];
      // Store the index of the previous element.
      var j:Int = i - 1;

      // While the previous element is greater than the current element,
      // move the previous element to the right and move the index to the left.
      while (j >= 0 && compare(input[j], current) > 0)
      {
        input[j + 1] = input[j];
        j--;
      }

      // Insert the current element into the array.
      input[j + 1] = current;
    }
  }
}
typedef CompareFunction<T> = T->T->Int;
