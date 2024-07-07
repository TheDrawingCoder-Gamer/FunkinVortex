package;

#if !macro
import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import lime.system.System;
import vortex.data.song.SongData;

#end
using StringTools;

#if sys
import flash.media.Sound;
import haxe.io.Path;
import lime.media.AudioBuffer;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;
#end

enum abstract Direction(Int) from Int to Int
{
	var left;
	var down;
	var up;
	var right;
}

enum NoteKind {
	Normal;
	Mine;
	Lift;
	Nuke;
	Custom(id: Int, name: String);
	// these two are incomplete and can prevent export of songs
	CustomName(name: String);
	CustomId(id: Int);
}



class Note extends FlxSprite
{
	public var parentState: PlayState;


	public static var swagWidth:Float = 160 * 0.7;

	public var colorSwap: ColorSwapShader.ColorSwap;

	static var noteFrameCollection:Null<FlxFramesCollection> = null;

	public var childSus: Null<SusNote> = null;
	public static final NOTE_AMOUNT: Int = 4;

	public function new(parent:PlayState)
	{
		super();

		this.parentState = parent;

		colorSwap = new ColorSwapShader.ColorSwap();

		if (noteFrameCollection == null) {
			initFrameCollection();
		}
		if (noteFrameCollection == null) throw 'ERROR: could not init note sprite animation';

		this.frames = noteFrameCollection;

		this.shader = colorSwap.shader;

		animation.add('tapNote', [1]);
		animation.add('liftNote', [2]);
		animation.add('tapNote-diag', [8]);
		animation.add('liftNote-diag', [9]);
		animation.add('tapNote-center', [16]);
		animation.add('liftNote-center', [17]);
		animation.add('mineNote', [21]);
		animation.add('nukeNote', [22]);

		setGraphicSize(Std.int(40));
		// updateHitbox();
		antialiasing = false;

	}
	static function initFrameCollection(): Void {
		noteFrameCollection = new FlxFramesCollection(null, ATLAS, null);
		if (noteFrameCollection == null) return;

		var frameCollectionNormal = FlxTileFrames.fromGraphic(FlxGraphic.fromAssetKey("assets/images/arrow.png"), new FlxPoint(16, 16));
		for (frame in frameCollectionNormal.frames) {
			noteFrameCollection.pushFrame(frame);
		}
	}

	public override function kill(): Void {
		super.kill();
		childSus = null;
	}
	public override function revive(): Void {
		super.revive();
		childSus = null;
	}

	public var noteQuant: Int = 0;

	public function updateNotePosition(?origin: FlxObject):Void {
		if (this.noteData == null) return;
		
		var cursorColumn = noteData.data;

		this.x = parentState.strumLine.members[cursorColumn].x;

		var stepTime: Float = noteData.getStepTime();

		if (stepTime >= 0) {
			this.y = stepTime * PlayState.LINE_SPACING;
		}

		if (origin != null) {
			this.x += origin.x;
			this.y += origin.y;
		}

	}
	public function playNoteAnimation(): Void {
		if (this.noteData == null) return;

		switch (noteData.kind) {
			case "mine":
				this.animation.play('mineNote');
			case "lift":
				this.animation.play('liftNote');
			case "nuke":
				this.animation.play('nukeNote');
			default:
				this.animation.play('tapNote');
		}

		this.setGraphicSize(Std.int(parentState.strumLine.members[0].width));
		this.updateHitbox();
		this.antialiasing = false;

		if (noteData.kind != "mine" && noteData.kind != "nuke") {
			switch (noteData.getDirection()) {
				case 0:
					angle = 90;
				case 1:
					angle = 0;
				case 2: 
					angle = 180;
				case 3:
					angle = -90;
			}
		}


		// 192
		noteQuant = 10;
		final row = noteData.rowTime;
		for (quant in 0...Constants.QUANT_ARRAY.length) {
			final daQuant = Constants.QUANT_ARRAY[quant];
			// ???
			if (row % Math.round(Constants.ROWS_PER_MEASURE / daQuant) == 0) {
				noteQuant = quant;
				break;
			}
		}

		colorSwap.hue = 0;
		colorSwap.saturation = 0;
		colorSwap.brightness = 0;
		switch (noteQuant) {
			// 4
			case 0:
			// 8
			case 1:
				colorSwap.hue = 235 / 360.0;
			// 12
			case 2:
				colorSwap.hue = 270 / 360.0;
			// 16
			case 3:
				colorSwap.hue = 60 / 360.0;
			// 24
			case 4:
				colorSwap.hue = 320 / 360.0;
			// 32
			case 5:
				colorSwap.hue = 20 / 360.0;
			// 48
			case 6:
				colorSwap.hue = 170 / 360.0;
			// 64
			case 7:
				colorSwap.hue = 120 / 360.0;
			// 20, 96, 192
			case 8:
				colorSwap.saturation = -1;
				colorSwap.brightness = -0.2;
		}
		if (childSus != null) {
			childSus.shader = colorSwap.shader;
		}

	}
	public var noteData(default, set): Null<SongNoteData>;
	function set_noteData(value:Null<SongNoteData>): Null<SongNoteData> {
		this.noteData = value;

		if (this.noteData == null) {
			this.kill();
			return this.noteData;
		}

		this.visible = true;

		this.playNoteAnimation();

		this.updateNotePosition();

		return this.noteData;
	}

	public function isNoteVisible(viewAreaBottom: Float, viewAreaTop:Float): Bool {
		var aboveViewArea = this.y + this.height < viewAreaTop;

		var belowViewArea = this.y > viewAreaBottom;

		return !aboveViewArea && !belowViewArea;
	}

	public static function wouldNoteBeVisible(viewAreaBottom: Float, viewAreaTop: Float, noteData: SongNoteData, ?origin:FlxObject): Bool {
		var stepTime = noteData.rowTime / Constants.ROWS_PER_STEP;
		var notePosY = stepTime * PlayState.LINE_SPACING;

		if (origin != null) notePosY += origin.y;

		var aboveViewArea = (notePosY + PlayState.LINE_SPACING < viewAreaTop);
		var belowViewArea = (notePosY > viewAreaBottom);

		return !aboveViewArea && !belowViewArea;
	}
}


