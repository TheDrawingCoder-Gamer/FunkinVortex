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



		animation.add('tapNote', [0]);
		animation.add('mineNote', [1]);
		animation.add('nukeNote', [2]);
		animation.add('liftNote', [6]);
		animation.add('customNote', [7]);

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
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



	public static final QUANT_ARRAY: Array<Int> = [4, 8, 12, 16, 24, 32, 48, 64, 192];
	public var noteQuant: Int = 0;

	public function updateNotePosition(?origin: FlxObject):Void {
		if (this.noteData == null) return;
		
		var cursorColumn = noteData.noteDirection;

		this.x = parentState.strumLine.members[cursorColumn].x;

		var stepTime: Float = noteData.getStepTime();

		if (stepTime >= 0) {
			this.y = stepTime * parentState.lineSpacing;
		}

		if (origin != null) {
			this.x += origin.x;
			this.y += origin.y;
		}

	}
	public function playNoteAnimation(): Void {
		if (this.noteData == null) return;

		switch (noteData.noteKind) {
			case Normal:
				this.animation.play('tapNote');
			case Mine:
				this.animation.play('mineNote');
			case Lift:
				this.animation.play('liftNote');
			case Nuke:
				this.animation.play('nukeNote');
			default:
				this.animation.play('customNote');
		}

		this.setGraphicSize(Std.int(parentState.strumLine.members[0].width));
		this.updateHitbox();
		this.antialiasing = false;

		switch (noteData.noteDirection % 4) {
			case 0:
				angle = -90;
			case 1:
				angle = 0;
			case 2: 
				angle = 180;
			case 3:
				angle = 90;
		}
		var stepTime: Float = noteData.getStepTime();
		final beatTime = stepTime / 4;
		final measureTime = stepTime / Conductor.instance.stepsPerMeasure;

		final smallestDeviation = measureTime / QUANT_ARRAY[QUANT_ARRAY.length - 1];

		for (quant in 0...QUANT_ARRAY.length) {
			final quantTime = (measureTime / QUANT_ARRAY[quant]);
			if ((noteData.strumTime + smallestDeviation) % quantTime < smallestDeviation * 2) {
				noteQuant = quant;
				break;
			}
		}

		colorSwap.hue = 0;
		colorSwap.saturation = 1;
		colorSwap.brightness = 1;
		switch (noteQuant) {
			// 4
			case 0:
			// 8
			case 1:
				colorSwap.hue = 235;
			// 12
			case 2:
				colorSwap.hue = 270;
			// 16
			case 3:
				colorSwap.hue = 60;
			// 24
			case 4:
				colorSwap.hue = 320;
			// 32
			case 5:
				colorSwap.hue = 20;
			// 48
			case 6:
				colorSwap.hue = 170;
			// 64
			case 7:
				colorSwap.hue = 120;
			// 192
			case 8:
				colorSwap.saturation = 0;
		}

	}
	public var noteData(default, set): Null<LegacyNoteData>;
	function set_noteData(value:Null<LegacyNoteData>): Null<LegacyNoteData> {
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
}

enum AltNoteData {
	Named(name: String);
	Id(id: Int);
}

class LegacyNoteData {
	public var strumTime: Float = 0;

	// this 
	public var noteDirection: Int = 0;
	public var noteKind: NoteKind = NoteKind.Normal;

	public var sustainLength: Float = 0;
	public var isSustainNote: Bool = false;

	public var altNote: Null<AltNoteData> = null;

	var _stepTime: Null<Float> = null;

	public function new() {}
	public function getStepTime(force: Bool = false): Float {
		if (!force && _stepTime != null) return _stepTime;
		return _stepTime = Conductor.instance.getTimeInSteps(this.strumTime);
	}
	public static function fromRaw(raw: NoteData, flipSides: Bool = false): LegacyNoteData {
		var res = new LegacyNoteData();
		res.strumTime = raw.strumTime;
		res.noteDirection = raw.noteDirection % 8;
		if (flipSides) {
			if (res.noteDirection > 3) {
				res.noteDirection = res.noteDirection % 4;
			} else {
				res.noteDirection += 4;
			}
		}
		if (raw.noteDirection < Note.NOTE_AMOUNT * 2) {
			res.noteKind = NoteKind.Normal;
		} else if (raw.noteDirection < Note.NOTE_AMOUNT * 4) {
			res.noteKind = NoteKind.Mine;
		} else if (raw.noteDirection < Note.NOTE_AMOUNT * 6) {
			res.noteKind = NoteKind.Lift;
		} else if (raw.noteDirection < Note.NOTE_AMOUNT * 8) {
			res.noteKind = NoteKind.Nuke;
		} else {
			res.noteKind = NoteKind.CustomId(Math.floor(raw.noteDirection / (Note.NOTE_AMOUNT * 2)) - 5);
		}

		return res;
	}
}
