package;

import flixel.FlxGame;
import haxe.ui.Toolkit;
import openfl.display.FPS;
import openfl.display.Sprite;
import flixel.FlxG;

class Main extends Sprite
{
	public function new()
	{
		super();
		Toolkit.init();
		Toolkit.theme = "dark";
		addChild(new FlxGame(0, 0, PlayState));
		addChild(new FPS(10, 3, 0xFFFFFF));
	}
}
