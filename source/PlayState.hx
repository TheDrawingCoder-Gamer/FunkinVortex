package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.weapon.FlxBullet;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import haxe.Json;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Stepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.styles.Style;
import openfl.media.Sound;
import vortex.data.song.SongData.*;

// import bulbytools.Assets;

enum abstract Snaps(Int) from Int to Int
{
	var Four;
	var Eight;
	var Twelve;
	var Sixteen;
	var Twenty;
	var TwentyFour;
	var ThirtyTwo;
	var FourtyEight;
	var SixtyFour;
	var NinetySix;
	var OneNineTwo;

	@:op(A == B) static function _(_, _):Bool;
}

enum abstract NoteTypes(Int) from Int to Int
{
	@:op(A == B) static function _(_, _):Bool;

	var Normal;
	var Lift;
	var Mine;
	var Death;
}

// By default sections come in steps of 16.
// i should be using tab menu... oh well
// we don't have to worry about backspaces ^-^

@:allow(SongDataEditor)
class PlayState extends FlxUIState
{
	// TODO: Variations are almost entirely seperate songs. Should I impl them?
	var songMetadata:SongMetaData;
	var songChartData:SongChartData;
	var chart:FlxSpriteGroup;
	var staffLines:FlxSprite;
	var staffLineGroup:FlxTypedSpriteGroup<Line>;
	var defaultLine:Line;
	public var strumLine:FlxSpriteGroup;
	var curRenderedNotes:FlxTypedSpriteGroup<Note>;
	var curRenderedSus:FlxSpriteGroup;
	var snaptext:FlxText;
	var curSnap:Float = 0;
	var curKeyType:Int = Normal;
	var menuBar:MenuBar;
	var curSelectedNote:Array<Dynamic>;
	var curHoldSelect:Array<Dynamic>;
	var gridSize = 40;
	public var lineSpacing = 40;
	var camFollow:FlxObject;
	var lastLineY:Int = 0;
	var sectionMarkers:Array<Float> = [];
	var songLengthInSteps:Int = 0;
	var songSectionTimes:Array<Float> = [];
	var useLiftNote:Bool = false;
	var noteControls:Array<Bool> = [false, false, false, false, false, false, false, false];
	var noteRelease:Array<Bool> = [false, false, false, false, false, false, false, false];
	var noteHold:Array<Bool> = [false, false, false, false, false, false, false, false];
	var curSectionTxt:FlxText;
	var selectBox:FlxSprite;
	var toolInfo:FlxText;
	var musicSound:Sound;
	var vocals:Sound;
	var songDataThingie:SongDataEditor;
	var holdSection:Int = -1;
	var selectedSection:Int = -1;
	var vocalSound:FlxSound;

	var snapInfo:Snaps = Four;
	var noteTypeText:FlxText;

	override public function create()
	{
		super.create();
		strumLine = new FlxSpriteGroup(0, 0);
		curRenderedNotes = new FlxTypedSpriteGroup<Note>();
		curRenderedSus = new FlxSpriteGroup();
		if (_song == null)
			_song = {
				song: 'Test',
				notes: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				stage: 'stage',
				gf: 'gf',
				isHey: false,
				speed: 1,
				isSpooky: false,
				isMoody: false,
				cutsceneType: "none",
				uiType: 'normal',
				isCheer: false,
				preferredNoteAmount: 4,
				forceJudgements: false,
				convertMineToNuke: false,
				mania: 0
			};
		// make it ridulously big
		staffLines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height * _song.notes.length, FlxColor.BLACK);
		staffLineGroup = new FlxTypedSpriteGroup<Line>();
		defaultLine = new Line();
		staffLineGroup.add(defaultLine);
		defaultLine.kill();
		generateStrumLine();
		strumLine.screenCenter(X);
		strumLine.x -= 250;
		trace(strumLine);
		staffLines.screenCenter(X);
		chart = new FlxSpriteGroup();
		chart.add(staffLines);
		chart.add(staffLineGroup);
		chart.add(strumLine);
		chart.add(curRenderedNotes);
		chart.add(curRenderedSus);
		#if !electron
		FlxG.mouse.useSystemCursor = true;
		#end
		// i think UIs in code get out of hand fast and i know others prefer it so.. - creator of the ui thing
		menuBar = new MenuBar();
		menuBar.customStyle.width = FlxG.width;
		var fileMenu = new Menu();
		fileMenu.text = "File";
		var saveChartMenu = new MenuItem();
		saveChartMenu.text = "Save Chart";
		// HEY UM SNIFF IS ACTUALLY LIKE A PROGRAM SILVAGUNNER USES SOOO
		saveChartMenu.onClick = function(e:MouseEvent)
		{
			var json = {
				"song": _song,
				"generatedBy": "FunkinVortex2"
			};
			var data = Json.stringify(json);
			if ((data != null) && (data.length > 0))
				FNFAssets.askToSave("song", data);
		};
		var openChartMenu = new MenuItem();
		openChartMenu.text = "Open Chart";
		openChartMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowse("json");
			future.onComplete(function(s:String)
			{
				_song = Song.loadFromJson(s);
				FlxG.resetState();
			});
		};
		var loadInstMenu = new MenuItem();
		loadInstMenu.text = "Load Instrument";
		loadInstMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg", "Select Instrument Tract");
			future.onComplete(function(s:String)
			{
				musicSound = Sound.fromFile(s);
				FlxG.sound.playMusic(musicSound);
				FlxG.sound.music.pause();
			});
		};
		var loadVoiceMenu = new MenuItem();
		loadVoiceMenu.text = "Load Vocals";
		loadVoiceMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg", "Select Voice Track");
			future.onComplete(function(s:String)
			{
				vocals = Sound.fromFile(s);
				vocalSound = FlxG.sound.load(vocals);
			});
		};
		/*
		var exportMenu = new MenuItem();
		exportMenu.text = "Export to base game";
		exportMenu.onClick = function(e:MouseEvent)
		{
			var cloneThingie = new Cloner();

			var sussySong:SwagSong = cloneThingie.clone(_song);
			for (i in 0...sussySong.notes.length)
			{
				for (j in 0...sussySong.notes[i].sectionNotes.length)
				{
					var noteThingie:Array<Dynamic> = sussySong.notes[i].sectionNotes[j];
					// remove lift info
					noteThingie[4] = null;
					if ((noteThingie[3] is Int))
					{
						if (noteThingie[3] > 0)
							noteThingie[3] = true;
						else
							noteThingie[3] = false;
					}
				}
				Reflect.deleteField(sussySong.notes[i], "altAnimNum");
			}
			var json = {
				"song": sussySong,
				"generatedBy": "FunkinVortexExport"
			};
			var data = Json.stringify(json);
			if ((data != null) && (data.length > 0))
				FNFAssets.askToSave("song", data);
		};
		*/
		fileMenu.addComponent(saveChartMenu);
		fileMenu.addComponent(openChartMenu);
		// fileMenu.addComponent(exportMenu);
		fileMenu.addComponent(loadInstMenu);
		fileMenu.addComponent(loadVoiceMenu);
		menuBar.addComponent(fileMenu);
		songDataThingie = new SongDataEditor(this);
		songDataThingie.x = FlxG.width / 2;
		songDataThingie.y = 100;
		songDataThingie.refreshUI(_song);
		lineSpacing = Std.int(strumLine.height);
		curSnap = lineSpacing * 4;
		drawChartLines();
		updateNotes();
		camFollow = new FlxObject(FlxG.width / 2, strumLine.getGraphicMidpoint().y);
		FlxG.camera.follow(camFollow, LOCKON);
		staffLines.y += strumLine.height / 2;
		snaptext = new FlxText(0, FlxG.height, 0, '4ths', 24);
		snaptext.y -= snaptext.height;
		snaptext.scrollFactor.set();
		curSectionTxt = new FlxText(200, FlxG.height, 0, 'Section: 0', 16);
		curSectionTxt.y -= curSectionTxt.height;
		curSectionTxt.scrollFactor.set();
		toolInfo = new FlxText(FlxG.width / 2, FlxG.height, 0, "a", 16);
		// don't immediately set text to '' because height??
		toolInfo.y -= toolInfo.height;
		toolInfo.text = 'hover over things to see what they do';
		noteTypeText = new FlxText(FlxG.width / 2, toolInfo.y, 0, "Normal Type", 16);
		noteTypeText.scrollFactor.set();
		// NOT PIXEL PERFECT
		toolInfo.scrollFactor.set();
		tempBpm = _song.bpm;
		Conductor.instance.mapBPMChanges(_song);
		selectBox = new FlxSprite().makeGraphic(1, 1, FlxColor.GRAY);
		selectBox.visible = false;
		selectBox.scrollFactor.set();
		// addUI();
		// add(staffLines);
		add(strumLine);
		add(curRenderedNotes);
		add(curRenderedSus);
		add(chart);
		add(snaptext);
		add(curSectionTxt);
		// add(openButton);

		add(menuBar);
		add(noteTypeText);
		// add(saveButton);
		// add(loadVocalsButton);
		// add(loadInstButton);
		// add(toolInfo);
		// add(ui_box);
		add(songDataThingie);
		add(selectBox);
		// add(haxeUIOpen);
	}

	function addSection(lengthInSteps:Int = 16)
	{
		var sec:Section.SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			altAnimNum: 0
		};

		_song.notes.push(sec);
		drawChartLines();
	}

	var tempBpm:Float = 0;

	private function loadFromFile():Void
	{
		var future = FNFAssets.askToBrowse("json");
		future.onComplete(function(s:String)
		{
			_song = Song.loadFromJson(s);
			FlxG.resetState();
		});
	}

	function copySection(?sectionNum:Int = 1)
	{
		var curSection = getSussySectionFromY(strumLine.y);
		var daSec = FlxMath.maxInt(curSection, sectionNum);
		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.instane.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateNotes([daSec]);
	}

	var selecting:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		camFollow.setPosition(FlxG.width / 2, strumLine.y);
		noteControls = [
			FlxG.keys.justPressed.ONE,
			FlxG.keys.justPressed.TWO,
			FlxG.keys.justPressed.THREE,
			FlxG.keys.justPressed.FOUR,
			FlxG.keys.justPressed.FIVE,
			FlxG.keys.justPressed.SIX,
			FlxG.keys.justPressed.SEVEN,
			FlxG.keys.justPressed.EIGHT
		];
		noteRelease = [
			FlxG.keys.justReleased.ONE,
			FlxG.keys.justReleased.TWO,
			FlxG.keys.justReleased.THREE,
			FlxG.keys.justReleased.FOUR,
			FlxG.keys.justReleased.FIVE,
			FlxG.keys.justReleased.SIX,
			FlxG.keys.justReleased.SEVEN,
			FlxG.keys.justReleased.EIGHT
		];
		noteHold = [
			FlxG.keys.pressed.ONE,
			FlxG.keys.pressed.TWO,
			FlxG.keys.pressed.THREE,
			FlxG.keys.pressed.FOUR,
			FlxG.keys.pressed.FIVE,
			FlxG.keys.pressed.SIX,
			FlxG.keys.pressed.SEVEN,
			FlxG.keys.pressed.EIGHT
		];
		if (FocusManager.instance.focus == null)
		{
			if (FlxG.keys.justPressed.UP || FlxG.mouse.wheel > 0)
			{
				moveStrumLine(-1);
			}
			else if (FlxG.keys.justPressed.DOWN || FlxG.mouse.wheel < 0)
			{
				moveStrumLine(1);
			}
			if (FlxG.keys.justPressed.S)
			{
				_song.notes[curSection()].mustHitSection = !_song.notes[curSection()].mustHitSection;
				// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
				updateNotes([curSection()]);
			}
			if (FlxG.keys.justPressed.Q)
			{
				curKeyType -= 1;
				curKeyType = cast FlxMath.wrap(curKeyType, 0, 99);
				switch (curKeyType)
				{
					case Normal:
						noteTypeText.text = "Normal Note";
					case Lift:
						noteTypeText.text = "Lift Note";
					case Mine:
						noteTypeText.text = "Mine Note";
					case Death:
						noteTypeText.text = "Death Note";
					case 4:
						// drain
						noteTypeText.text = "Drain Note";
					default:
						noteTypeText.text = 'Custom Note ${curKeyType - 4}';
				}
			}
			else if (FlxG.keys.justPressed.E)
			{
				curKeyType += 1;
				curKeyType = cast FlxMath.wrap(curKeyType, 0, 99);
				switch (curKeyType)
				{
					case Normal:
						noteTypeText.text = "Normal Note";
					case Lift:
						noteTypeText.text = "Lift Note";
					case Mine:
						noteTypeText.text = "Mine Note";
					case Death:
						noteTypeText.text = "Death Note";
					case 4:
						// drain
						noteTypeText.text = "Drain Note";
					default:
						noteTypeText.text = 'Custom Note ${curKeyType - 4}';
				}
			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				changeSnap(true);
			}
			else if (FlxG.keys.justPressed.LEFT)
			{
				changeSnap(false);
			}
			if (FlxG.keys.justPressed.ESCAPE && curSelectedNote != null)
			{
				deselectNote();
			}
			if (FlxG.keys.justPressed.HOME)
			{
				strumLine.y = 0;
				moveStrumLine(0);
			}
			/*
				if (FlxG.keys.pressed.SHIFT && FlxG.mouse.justPressed)
				{
					selecting = true;
					selectBox.x = FlxG.mouse.screenX;
					selectBox.y = FlxG.mouse.screenY;
					selectBox.scale.x = 1;
					selectBox.scale.y = 1;
					selectBox.visible = true;
				}
				if (FlxG.mouse.justReleased && selecting)
				{
					selecting = false;
					selectBox.visible = false;
				}

				if (selecting)
				{
					selectBox.scale.x = selectBox.x - FlxG.mouse.screenX;
					selectBox.scale.y = selectBox.y - FlxG.mouse.screenY;
					selectBox.offset.x = (selectBox.x - FlxG.mouse.screenX) / 2;
					selectBox.offset.y = (selectBox.y - FlxG.mouse.screenY) / 2;
				}
			 */

			if (FlxG.keys.pressed.SHIFT && FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					for (note in curRenderedNotes.members)
					{
						if (FlxG.mouse.overlaps(note))
						{
							strumLine.y = note.y;
							var goodSection = curSection();
							var noteData = note.noteData;
							if (_song.notes[goodSection].mustHitSection)
							{
								var sussyInfo = 0;
								if (noteData > 3)
								{
									sussyInfo = noteData % 4;
								}
								else
								{
									sussyInfo = noteData + 4;
								}
								noteData = sussyInfo;
							}
							selectNote(noteData);
							break;
						}
					}
				}
			}
			if (FlxG.keys.pressed.CONTROL && FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					for (note in curRenderedNotes.members)
					{
						if (FlxG.mouse.overlaps(note))
						{
							strumLine.y = note.y;
							var goodSection = curSection();
							var noteData = note.noteData;
							if (_song.notes[goodSection].mustHitSection)
							{
								var sussyInfo = 0;
								if (noteData > 3)
								{
									sussyInfo = noteData % 4;
								}
								else
								{
									sussyInfo = noteData + 4;
								}
								noteData = sussyInfo;
							}
							addNote(noteData);
							break;
						}
					}
				}
			}
			/*
				if (curSelectedNote != null)
				{
					curSelectedNote[3] = Std.int(noteInfo.stepperAltNote.value);
			}*/
			if (FlxG.keys.justPressed.SPACE && FlxG.sound.music != null)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if (_song.needsVoices && vocalSound != null)
					{
						vocalSound.pause();
					}
				}
				else
				{
					FlxG.sound.music.time = getSussyStrumTime(strumLine.y);
					FlxG.sound.music.play();
					if (_song.needsVoices && vocalSound != null)
					{
						vocalSound.play();
					}
				}
			}
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				strumLine.y = getSussyYPos(FlxG.sound.music.time);
				curSectionTxt.text = 'Section: ' + getSussySectionFromY(strumLine.y);
				// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
				if (_song.needsVoices && vocalSound != null && !CoolUtil.nearlyEquals(vocalSound.time, FlxG.sound.music.time, 2))
				{
					vocalSound.time = FlxG.sound.music.time;
				}
			}
		}

		for (i in 0...noteControls.length)
		{
			if (!noteControls[i] || FocusManager.instance.focus != null)
				continue;
			if (FlxG.keys.pressed.CONTROL)
			{
				selectNote(i);
			}
			else if (FlxG.keys.pressed.A)
			{
				convertToRoll(i);
			}
			else
			{
				addNote(i);
			}
		}
		for (i in 0...noteRelease.length)
		{
			if (!noteRelease[i])
				continue;
			if (curHoldSelect != null && curHoldSelect[1] == getGoodInfo(i))
			{
				curHoldSelect = null;
				holdSection = -1;
			}
		}
	}

	private function moveStrumLine(change:Int = 0)
	{
		var oldSection = curSection();
		strumLine.y += change * curSnap;

		if (change != 0)
			strumLine.y = Math.round(strumLine.y / curSnap) * curSnap;
		var newSection = curSection();
		// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
		if (curSelectedNote != null)
		{
			curSelectedNote[2] = getSussyStrumTime(strumLine.y) - curSelectedNote[0];
			curSelectedNote[2] = FlxMath.bound(curSelectedNote[2], 0);
			updateNotes([selectedSection]);
		}
		if (curHoldSelect != null)
		{
			curHoldSelect[2] = getSussyStrumTime(strumLine.y) - curHoldSelect[0];
			curHoldSelect[2] = FlxMath.bound(curHoldSelect[2], 0);
			updateNotes([holdSection]);
		}
		if (oldSection != newSection)
		{
			curSectionTxt.text = 'Section: ' + newSection;
		}
	}

	private function generateStrumLine()
	{
		for (i in 0...8)
		{
			var babyArrow = new FlxSprite(strumLine.x, strumLine.y);
			babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');

			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
			switch (i)
			{
				case 0 | 4:
					babyArrow.animation.play("purple");
				case 5 | 1:
					babyArrow.animation.play("blue");
				case 2 | 6:
					babyArrow.animation.play("green");
				case 7 | 3:
					babyArrow.animation.play("red");
			}
			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int(40));
			babyArrow.x += 160 * babyArrow.scale.x * i + 50;
			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();
			babyArrow.ID = i;
			strumLine.add(babyArrow);
		}
	}

	/** 
	 * current section : )
	 */
	inline public function curSection()
	{
		return getSussySectionFromY(strumLine.y);
	}

	private function drawChartLines()
	{
		// staffLines.makeGraphic(FlxG.width, FlxG.height * _song.notes.length, FlxColor.TRANSPARENT);

		for (i in 0..._song.notes.length)
		{
			for (o in 0..._song.notes[i].lengthInSteps)
			{
				var lineColor:FlxColor = FlxColor.GRAY;
				if (o == 0)
				{
					lineColor = FlxColor.WHITE;
					sectionMarkers.push(lineSpacing * ((i * 16) + o));
				}
				FlxSpriteUtil.drawLine(staffLines, FlxG.width * -0.5, lineSpacing * ((i * 16) + o), FlxG.width * 1.5, lineSpacing * ((i * 16) + o),
					{color: lineColor, thickness: 5});
				var line = staffLineGroup.recycle(Line);
				line.color = lineColor;

				line.setGraphicSize(Std.int(strumLine.width), 5);
				line.updateHitbox();
				line.x = strumLine.x + 50;
				line.y = lineSpacing * ((i * 16) + o);

				lastLineY = lineSpacing * ((i * 16) + o);
			}
		}
	}

	function convertToRoll(id:Int)
	{
		selectNote(id);
		var sections = [];
		// nothing fancy, just generate rolls
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] > 0)
			{
				for (sussy in 0...Math.floor(curSelectedNote[2] / Conductor.stepCrochet))
				{
					var goodSection = getSussySectionFromY(getSussyYPos(curSelectedNote[0] + sussy * Conductor.stepCrochet));
					sections.push(goodSection);
					var noteData = id;
					if (_song.notes[goodSection].mustHitSection)
					{
						var sussyInfo = 0;
						if (noteData > 3)
						{
							sussyInfo = noteData % 4;
						}
						else
						{
							sussyInfo = noteData + 4;
						}
						noteData = sussyInfo;
					}
					_song.notes[goodSection].sectionNotes.push([
						curSelectedNote[0] + sussy * Conductor.stepCrochet,
						noteData,
						0,
						curSelectedNote[3],
						curSelectedNote[4]
					]);
				}
			}
			curSelectedNote[2] = 0;
		}
		deselectNote();
		updateNotes(sections);
	}

	private function addNote(id:Int):Void
	{
		var noteStrum = getSussyStrumTime(strumLine.members[id].y);
		var noteData = id;
		var noteSus = 0;
		var curSection = curSection();
		if (_song.notes[curSection].mustHitSection)
		{
			var sussyInfo = 0;
			if (noteData > 3)
			{
				sussyInfo = noteData % 4;
			}
			else
			{
				sussyInfo = noteData + 4;
			}
			noteData = sussyInfo;
		}
		switch (curKeyType)
		{
			case Lift:
				noteData += 16;
			case Mine:
				noteData += 8;
			case Death:
				noteData += 24;
			case Normal:
			// no
			case 4:
				noteData += 32;
			case key:
				noteData += 8 * key;
		}
		// prefer overloading : )
		var goodArray:Array<Dynamic> = [noteStrum, noteData, noteSus, false, curKeyType == Lift];
		for (note in _song.notes[curSection].sectionNotes)
		{
			if (CoolUtil.truncateFloat(note[0], 1) == CoolUtil.truncateFloat(goodArray[0], 1) && note[1] % 8 == noteData % 8)
			{
				_song.notes[curSection].sectionNotes.remove(note);
				// if it was not the same type
				// we replace it instead of outright deleting it
				if (note[1] != noteData)
				{
					break;
				}
				updateNotes([curSection]);
				return;
			}
		}
		_song.notes[curSection].sectionNotes.push(goodArray);
		curHoldSelect = goodArray;
		holdSection = curSection;
		updateNotes([curSection]);
	}

	private function changeSnap(increase:Bool)
	{
		// i have no idea why it isn't throwing a hissy fit. Let's keep it that way.
		if (increase)
		{
			snapInfo += 1;
		}
		else
		{
			snapInfo -= 1;
		}
		snapInfo = cast FlxMath.wrap(cast snapInfo, 0, cast(OneNineTwo));
		switch (snapInfo)
		{
			case Four:
				snaptext.text = '4ths';
				curSnap = (lineSpacing * 16) / 4;
			case Eight:
				snaptext.text = '8ths';
				curSnap = (lineSpacing * 16) / 8;
			case Twelve:
				snaptext.text = '12ths';
				curSnap = (lineSpacing * 16) / 12;
			case Sixteen:
				snaptext.text = '16ths';
				curSnap = (lineSpacing * 16) / 16;
			case Twenty:
				snaptext.text = '20ths';
				curSnap = (lineSpacing * 16) / 20;
			case TwentyFour:
				snaptext.text = '24ths';
				curSnap = (lineSpacing * 16) / 24;
			case ThirtyTwo:
				snaptext.text = '32nds';
				curSnap = (lineSpacing * 16) / 32;
			case FourtyEight:
				snaptext.text = '48ths';
				curSnap = (lineSpacing * 16) / 48;
			case SixtyFour:
				snaptext.text = '64ths';
				curSnap = (lineSpacing * 16) / 64;
			case NinetySix:
				snaptext.text = '96ths';
				curSnap = (lineSpacing * 16) / 96;
			case OneNineTwo:
				snaptext.text = '192nds';
				curSnap = (lineSpacing * 16) / 192;
		}
	}

	private function deselectNote():Void
	{
		curSelectedNote = null;
		selectedSection = -1;
		// sectionInfo.visible = true;
		// noteInfo.visible = false;
	}

	private function selectNote(id:Int):Void
	{
		var noteStrum = getSussyStrumTime(strumLine.members[id].y);
		var noteData = id;
		var noteSus = 0;
		var curSection = curSection();
		if (_song.notes[curSection].mustHitSection)
		{
			var sussyInfo = 0;
			if (noteData > 3)
			{
				sussyInfo = noteData % 4;
			}
			else
			{
				sussyInfo = noteData + 4;
			}
			noteData = sussyInfo;
		}
		var goodArray:Array<Dynamic> = [noteStrum, noteData, noteSus, false];

		for (note in _song.notes[curSection].sectionNotes)
		{
			if (CoolUtil.truncateFloat(note[0], 1) == CoolUtil.truncateFloat(goodArray[0], 1) && note[1] == noteData)
			{
				curSelectedNote = note;
				selectedSection = curSection;
				// sectionInfo.visible = false;
				// noteInfo.visible = true;
				// noteInfo.updateNote(curSelectedNote);
				updateNotes([curSection]);
				// updateNoteUI();
				songDataThingie.refreshNoteUI(note);
				return;
			}
		}
	}

	public function getGoodInfo(noteData:Int)
	{
		var curSection = curSection();
		if (_song.notes[curSection].mustHitSection)
		{
			var sussyInfo = 0;
			if (noteData > 3)
			{
				sussyInfo = noteData % 4;
			}
			else
			{
				sussyInfo = noteData + 4;
			}
			noteData = sussyInfo;
		}
		return noteData;
	}

	private function updateNotes(?sections:Array<Int>)
	{
		// drawChartLines();
		if (sections == null)
		{
			sections = CoolUtil.numberArray(_song.notes.length - 1);
		}
		var badKids:Array<Note> = [];
		for (note in curRenderedNotes.members)
		{
			if (note != null && sections.contains(getSussySectionFromY(note.y)))
			{
				badKids.push(note);
			}
		}
		for (kid in badKids)
		{
			curRenderedNotes.remove(kid);
			kid.destroy();
		}
		var badSus:Array<FlxSprite> = [];
		for (sus in curRenderedSus.members)
		{
			if (sus != null && sections.contains(getSussySectionFromY(sus.y - lineSpacing)))
			{
				badSus.push(sus);
			}
		}
		for (sus in badSus)
		{
			curRenderedSus.remove(sus);
			sus.destroy();
		}
		for (j in 0..._song.notes.length)
		{
			// skip it if it doesn't need to be done
			if (!sections.contains(j))
				continue;
			var sectionInfo:Array<Dynamic> = _song.notes[j].sectionNotes;
			// todo,  bpm support
			/*
				if (_song.notes[i].changeBPM && _song.notes[i].bpm > 0)
				{
					Conductor.changeBPM(_song.notes[i].bpm);
			}*/
			Conductor.changeBPM(_song.bpm);
			songSectionTimes.push(songLengthInSteps);
			songLengthInSteps += _song.notes[j].lengthInSteps;

			for (i in sectionInfo)
			{
				var daNoteInfo = i[1];
				var daStrumTime = i[0];
				var daSus = i[2];
				var daLift = i[4];
				var note = new Note(daStrumTime, daNoteInfo, null, false, daLift);
				note.sustainLength = daSus;
				note.setGraphicSize(Std.int(strumLine.members[0].width));
				note.updateHitbox();
				note.x = strumLine.members[daNoteInfo % 8].x;
				if (_song.notes[j].mustHitSection)
				{
					var sussyInfo = 0;
					if (daNoteInfo % 8 > 3)
					{
						sussyInfo = daNoteInfo % 8 - 4;
					}
					else
					{
						sussyInfo = daNoteInfo % 8 + 4;
					}
					note.x = strumLine.members[sussyInfo].x;
				}
				note.y = Math.floor(getYfromStrum(daStrumTime, j));
				curRenderedNotes.add(note);
				if (daSus > 0)
				{
					var sustainVis:FlxSprite = new FlxSprite(note.x + note.width / 2,
						note.y + lineSpacing).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, lineSpacing * 16)),
						FlxColor.BLUE);
					curRenderedSus.add(sustainVis);
				}
			}
		}
	}

	private function getYfromStrum(strumTime:Float, section:Int):Float
	{
		return FlxMath.remapToRange(strumTime, sectionStartTime(section), sectionStartTime(section + 1), sectionMarkers[section], sectionMarkers[section + 1]);
	}

	private function getStrumTime(yPos:Float, section:Int):Float
	{
		return FlxMath.remapToRange(yPos, sectionMarkers[section], sectionMarkers[section + 1], sectionStartTime(section), sectionStartTime(section + 1));
	}

	// Should be called "getAmbiguousStrumTime", too lazy to name it that
	private function getSussyStrumTime(yPos:Float):Float
	{
		for (i in 0..._song.notes.length)
		{
			if (yPos >= sectionMarkers[i] && yPos < sectionMarkers[i + 1])
			{
				return getStrumTime(yPos, i);
			}
		}
		return 0;
	}

	private function getSussyYPos(strumTime:Float):Float
	{
		for (i in 0..._song.notes.length)
		{
			if (strumTime >= sectionStartTime(i) && strumTime < sectionStartTime(i + 1))
			{
				return getYfromStrum(strumTime, i);
			}
		}
		return 0;
	}

	function getSussySectionFromY(yPos:Float):Int
	{
		for (i in 0..._song.notes.length)
		{
			if (yPos >= sectionMarkers[i] && yPos < sectionMarkers[i + 1])
			{
				return i;
			}
		}
		return 0;
	}

	function sectionStartTime(section:Int):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...section)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}
}

class Line extends FlxSprite
{
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		makeGraphic(FlxG.width, 5, FlxColor.WHITE);
	}
}
