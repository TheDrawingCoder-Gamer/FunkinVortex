package;

import flixel.FlxGame;
import haxe.ui.Toolkit;
import openfl.display.FPS;
import openfl.display.Sprite;
import flixel.FlxG;
// import flixel.input.keyboard.FlxKey;

class Main extends Sprite
{
	public function new()
	{
		super();
		Toolkit.init();
		Toolkit.theme = "dark";
		addChild(new FlxGame(0, 0, PlayState, 60, 60, true));
		FlxG.sound.muteKeys = null;
		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;
		// addChild(new FPS(10, 3, 0xFFFFFF));
	}
}
