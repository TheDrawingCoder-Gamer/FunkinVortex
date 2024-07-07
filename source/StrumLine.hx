package;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import vortex.data.song.Gamemode;
import flixel.graphics.FlxGraphic;

class StrumLine extends FlxTypedSpriteGroup<StrumNote> {
	public var gamemode(default, null): Gamemode = null;
	public var noteCount(default, null): Int = 4;
	public function new() {
		super();
		// hardcoded max
		for (i in 0...30) {
			final strumNote = new StrumNote();
			add(strumNote);
		}
	}
	public function setup(gamemode: Gamemode) {
		this.gamemode = gamemode;
		for (member in this.members) {
			member.kill();
		}
		this.noteCount = gamemode.noteCount;
		for (i in 0...noteCount) {
			final strumNote = members[i];
			strumNote.revive();
			strumNote.setup(i, gamemode);
			strumNote.x = this.x + 45 * i;
			strumNote.y = this.y;
		}

	}
	public function get(index: Int): Null<StrumNote> {
		var i = 0;
		for (item in this.members) {
			if (!item.alive) continue;
			if (i == index) return item;
			i++;
		}
		return null;
	}
}

// A strumline note : )
class StrumNote extends FlxSprite {
	public var colorSwap: ColorSwapShader.ColorSwap;
	var animVariant: String = "norm";
	public function new() {
		super();

		colorSwap = new ColorSwapShader.ColorSwap();

		this.frames = FlxTileFrames.fromGraphic(FlxGraphic.fromAssetKey("assets/images/arrow.png"), new FlxPoint(16, 16));

		this.shader = colorSwap.shader;

		animation.add('static-normal', [0]);
		animation.add('pressed-normal', [2, 4]);
		animation.add('confirm-normal', [5, 6]);

		animation.add('static-diagonal', [7]);
		animation.add('pressed-diagonal', [9, 11]);
		animation.add('confirm-diagonal', [12, 13]);

		animation.add('static-center', [14]);
		animation.add('pressed-center', [16, 18]);
		animation.add('confirm-center', [19, 20]);

		animation.add('static-bar', [23]);
		animation.add('pressed-bar', [24, 26]);
		animation.add('confirm-bar', [27, 28]);

		animation.add('static-circle', [29]);
		animation.add('pressed-circle', [30, 32]);
		animation.add('confirm-circle', [33, 34]);

		this.active = true;
		this.antialiasing = false;

		setGraphicSize(40);
		updateHitbox();

	}

	public function setup(index: Int, gamemode: Gamemode) {
		animVariant = cast gamemode.notes[index].noteKind;
		angle = gamemode.notes[index].rot90 * 90;
		playStatic();
	}

	public function playStatic():Void {
		this.animation.play('static-$animVariant', true);
	}
	public function playPress(): Void {
		this.active = true;
		this.animation.play('pressed-$animVariant', true);
	}
	public function playConfirm(): Void {
		this.active = true;
		this.animation.play('confirm-$animVariant', true);
	}
	public override function update(elapsed:Float): Void {
		super.update(elapsed);
		// ?
	}
}
