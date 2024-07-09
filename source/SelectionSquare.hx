package;

import flixel.addons.display.FlxSliceSprite;
import flixel.math.FlxRect;
import vortex.data.song.SongData.SongEventData;
import vortex.data.song.SongData.SongNoteData;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class SelectionSquare extends FlxSliceSprite {
	public var noteData:Null<SongNoteData>;
	public var eventData:Null<SongEventData>;

	public static var selectionSquareBitmap:BitmapData = null;
	public static final BORDER_WIDTH: Int = 1;
	public function new() {
		if (selectionSquareBitmap == null)
			buildSelectionBitmap();
		// ??
		super(selectionSquareBitmap,
				new FlxRect(BORDER_WIDTH + 4, 
					BORDER_WIDTH + 4, 
					PlayState.LINE_SPACING - (2 * BORDER_WIDTH + 8), 
					PlayState.LINE_SPACING - (2 * BORDER_WIDTH + 8)), 
				PlayState.LINE_SPACING,PlayState.LINE_SPACING
				);
	}
	public static function buildSelectionBitmap(): Void {
		selectionSquareBitmap = new BitmapData(PlayState.LINE_SPACING, PlayState.LINE_SPACING, true);

		selectionSquareBitmap.fillRect(new Rectangle(0, 0, PlayState.LINE_SPACING, PlayState.LINE_SPACING), 0xFF339933);
		selectionSquareBitmap.fillRect(new Rectangle(BORDER_WIDTH, 
						BORDER_WIDTH + 1, 
						PlayState.LINE_SPACING - BORDER_WIDTH - 3, 
						PlayState.LINE_SPACING - BORDER_WIDTH - 3), 
				0x4033FF33);
	}
}
