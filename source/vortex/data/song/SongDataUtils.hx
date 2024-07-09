package vortex.data.song;

import flixel.util.FlxSort;
import vortex.data.song.SongData.SongTimeChange;
import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongData.SongEventData;

class SongDataUtils {
  public static function sortTimeChanges(timeChanges: Array<SongTimeChange>, desc: Bool = false): Array<SongTimeChange> {
    timeChanges.sort(function(a:SongTimeChange,b:SongTimeChange): Int {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.rowTime, b.rowTime);
    });
    return timeChanges;
  }
  public static function quantizeNote(beatLength: Float, strum: Float): Int {
    final measureTime = beatLength * 4;

    final smallestDeviation = measureTime / Constants.QUANT_ARRAY[Constants.QUANT_ARRAY.length - 1];

    for (quant in 0...Constants.QUANT_ARRAY.length) {
      final quantTime = (measureTime / Constants.QUANT_ARRAY[quant]);
      if ((strum + smallestDeviation) % quantTime < smallestDeviation * 2) {
        return quant;
      }
    }
    return 0;
  }
  public static function subtractNotes(notes:Array<SongNoteData>, subtrahend:Array<SongNoteData>)
  {
    if (notes.length == 0 || subtrahend.length == 0) return notes;

    var result = notes.filter(function(note:SongNoteData):Bool {
      for (x in subtrahend)
      {
        // The currently iterated note is in the subtrahend array.
        // SongNoteData's == operation has been overridden so that this will work.
        if (x == note) return false;
      }

      return true;
    });

    return result;
  }
  public static function subtractEvents(events:Array<SongEventData>, subtrahend:Array<SongEventData>)
  {
    if (events.length == 0 || subtrahend.length == 0) return events;

    var result = events.filter(function(event:SongEventData):Bool {
      for (x in subtrahend)
      {
        // The currently iterated note is in the subtrahend array.
        // SongNoteData's == operation has been overridden so that this will work.
        if (x == event) return false;
      }

      return true;
    });

    return result;
  }
}
