package;

import Song.SwagSong;
import haxe.ui.containers.TabView;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

@:build(haxe.ui.macros.ComponentMacros.build("assets/data/tabmenu.xml"))
class SongDataEditor extends TabView
{
	var playstate:PlayState;

	public function new(playstate:PlayState)
	{
		super();
		this.playstate = playstate;
	}

	private var _song(get, set):Song.SwagSong;

	private var _note(get, set):Null<NoteData>;

	private function get__note():Null<NoteData>
	{
		return cast playstate.curSelectedNote;
	}

	private function set__note(value:Null<NoteData>):Null<NoteData>
	{
		playstate.curSelectedNote = cast value;
		return value;
	}

	private function get__song():SwagSong
	{
		return PlayState._song;
	}

	private function set__song(goodSong:SwagSong):SwagSong
	{
		PlayState._song = goodSong;
		refreshUI(PlayState._song);
		return goodSong;
	}

	public function refreshUI(goodSong:SwagSong)
	{
		bfText.text = goodSong.player1;
		enemyText.text = goodSong.player2;
		gfText.text = goodSong.gf;
		stageText.text = goodSong.stage;
		uiText.text = goodSong.uiType;
		songTitle.text = goodSong.song;
		needsVoices.selected = goodSong.needsVoices;
		forceJudgements.selected = goodSong.forceJudgements;
		convertMines.selected = goodSong.convertMineToNuke;
		// muteInst doesn't mean anything to the song itself, used only as a editor helper
		isspooky.selected = goodSong.isSpooky;
		ismoody.selected = goodSong.isMoody;
		ishey.selected = goodSong.isHey;
		ischeer.selected = goodSong.isCheer;
		songspeed.pos = goodSong.speed;
		songbpm.pos = goodSong.bpm;
	}

	public function refreshSectionUI(section:Section.SwagSection)
	{
		sectionbpm.pos = section.bpm;
		altsection.pos = section.altAnimNum;
		sectionlength.pos = section.lengthInSteps;
		musthitsection.selected = section.altAnim;
		changebpmsection.selected = section.changeBPM;
	}

	public function refreshNoteUI(goodNote:NoteData)
	{
		var altNote:Any = goodNote.altNote;
		if ((altNote is Bool))
		{
			altnotestep.pos = altNote ? 1 : 0;
			altnotecheck.selected = altNote;
		}
		else
		{
			altnotestep.pos = cast(altNote : Int);
			altnotecheck.selected = cast(altNote : Int) != 0;
		}
		if (goodNote.healMultiplier != null)
		{
			noteheal.pos = goodNote.healMultiplier;
		}
		if (goodNote.damageMultiplier != null)
		{
			notehurt.pos = goodNote.damageMultiplier;
		}
		if (goodNote.consistentHealth != null)
		{
			consistentHealth.selected = goodNote.consistentHealth;
		}
		if (goodNote.timingMultiplier != null)
		{
			notetiming.pos = goodNote.timingMultiplier;
		}
		if (goodNote.shouldBeSung != null)
		{
			shouldSing.selected = goodNote.shouldBeSung;
		}
		if (goodNote.ignoreHealthMods != null)
		{
			ignoreMods.selected = goodNote.ignoreHealthMods;
		}
		if (goodNote.animSuffix != null)
		{
			animSuffix.text = goodNote.animSuffix;
		}
	}

	@:bind(sectionbpm, UIEvent.CHANGE)
	function change_sectionbpm(_:UIEvent)
	{
		var curSection = playstate.getSussySectionFromY(playstate.strumLine.y);
		if (_song.notes[curSection] != null)
			_song.notes[curSection].bpm = sectionbpm.pos;
		// we shouldn't need to update notes??
	}

	@:bind(swapsection, MouseEvent.CLICK)
	function click_swapsection(_)
	{
		var curSection = playstate.curSection();
		if (_song.notes[curSection] == null)
			return;
		for (i in 0..._song.notes[curSection].sectionNotes.length)
		{
			var note = _song.notes[curSection].sectionNotes[i];
			note[1] = (note[1] + 4) % 8;
			_song.notes[curSection].sectionNotes[i] = note;
		}
		playstate.updateNotes([curSection]);
	}

	@:bind(copysection, MouseEvent.CLICK)
	function click_copysection(_)
	{
		playstate.copySection(Std.int(copyid.pos));
	}

	@:bind(addsection, MouseEvent.CLICK)
	function click_addsection(_)
	{
		playstate.addSection();
	}

	@:bind(clearsection, MouseEvent.CLICK)
	function click_clearsection(_)
	{
		var curSection = playstate.curSection();
		if (_song.notes[curSection] == null)
			return;
		_song.notes[curSection].sectionNotes = [];
		playstate.updateNotes([curSection]);
	}

	@:bind(musthitsection, UIEvent.CHANGE)
	function change_musthitsection(_)
	{
		var curSection = playstate.curSection();
		if (_song.notes[curSection] != null)
			_song.notes[curSection].mustHitSection = musthitsection.selected;
		playstate.updateNotes([curSection]);
	}

	@:bind(changebpmsection, UIEvent.CHANGE)
	function change_changebpmsection(_)
	{
		var curSection = playstate.curSection();
		if (_song.notes[curSection] != null)
			_song.notes[curSection].changeBPM = changebpmsection.selected;
	}

	@:bind(altnotecheck, UIEvent.CHANGE)
	function change_altnotecheck(_)
	{
		if (_note != null)
		{
			_note.altNote = altnotecheck.selected;
		}
		refreshNoteUI(_note);
	}

	@:bind(sectionlength, UIEvent.CHANGE)
	function change_sectionlength(_)
	{
		var curSection = playstate.curSection();
		if (_song.notes[curSection] != null)
		{
			_song.notes[curSection].lengthInSteps = Std.int(sectionlength.pos);
		}
		// Change all sections after this
		playstate.updateNotes(CoolUtil.numberArray(_song.notes.length - 1, curSection));
	}

	@:bind(songspeed, UIEvent.CHANGE)
	function change_songspeed(_)
	{
		_song.speed = songspeed.pos;
	}

	@:bind(songbpm, UIEvent.CHANGE)
	function change_songbpm(_)
	{
		playstate.tempBpm = songbpm.pos;
		Conductor.mapBPMChanges(_song);
		Conductor.changeBPM(playstate.tempBpm);
	}

	@:bind(altsection, UIEvent.CHANGE)
	function change_altsection(_)
	{
		var curSection = playstate.curSection();
		if (_song.notes[curSection] != null)
		{
			_song.notes[curSection].altAnimNum = Std.int(altsection.pos);
		}
	}

	@:bind(altnotestep, UIEvent.CHANGE)
	function change_altnotestep(_)
	{
		if (_note != null)
		{
			_note.altNote = altnotestep.pos;
			refreshNoteUI(_note);
		}
	}

	@:bind(noteheal, UIEvent.CHANGE)
	function change_noteheal(_)
	{
		if (_note != null)
		{
			_note.healMultiplier = noteheal.pos;
			refreshNoteUI(_note);
		}
	}

	@:bind(notehurt, UIEvent.CHANGE)
	function change_notehurt(_)
	{
		if (_note != null)
		{
			_note.damageMultiplier = notehurt.pos;
			refreshNoteUI(_note);
		}
	}

	@:bind(consistentHealth, UIEvent.CHANGE)
	function change_consistentHealth(_)
	{
		if (_note != null)
		{
			_note.consistentHealth = consistentHealth.selected;
		}
	}

	@:bind(notetiming, UIEvent.CHANGE)
	function change_notetiming(_)
	{
		if (_note != null)
			_note.timingMultiplier = notetiming.pos;
	}

	@:bind(shouldSing, UIEvent.CHANGE)
	function change_shouldSing(_)
	{
		if (_note != null)
		{
			_note.shouldBeSung;
		}
	}

	@:bind(ignoreMods, UIEvent.CHANGE)
	function change_ignoreMods(_)
	{
		if (_note != null)
		{
			_note.ignoreHealthMods = ignoreMods.selected;
		}
	}
}
