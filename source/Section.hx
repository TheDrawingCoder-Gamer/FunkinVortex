package;

import hxjsonast.Json;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var altAnimNum:Null<Int>;
}

class Section
{

	public var sectionNotes:Array<Note.LegacyNoteData> = [];

	public var lengthInSteps:Int = 16;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	public var bpm: Float = 100;
	public var changeBPM: Bool = false;
	public var altAnim: Bool = false;
	public var altAnimNum: Null<Int> = null;

	/**
	 *	Copies the first section into the second section!
	 */

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}

	public static function fromRaw(raw: SwagSection): Section {
		final res = new Section(raw.lengthInSteps);
		res.bpm = raw.bpm;
		res.typeOfSection = raw.typeOfSection;
		res.mustHitSection = raw.mustHitSection;
		res.altAnim = raw.altAnim;
		res.altAnimNum = raw.altAnimNum;

		for (note in raw.sectionNotes) {
			res.sectionNotes.push(Note.LegacyNoteData.fromRaw(note, raw.mustHitSection));	
		}

		return res;
	}
}
