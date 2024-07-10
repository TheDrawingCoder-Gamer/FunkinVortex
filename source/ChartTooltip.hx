package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;

class ChartTooltip extends FlxSpriteGroup {
	public var backdrop: FlxSprite;
	public var text: FlxText;

	public function new() {
		super();
		backdrop = new FlxSprite().loadGraphic(FlxGraphic.fromAssetKey("assets/images/charttooltip.png"));
		backdrop.setGraphicSize(0, 40);
		backdrop.updateHitbox();
		add(backdrop);

		text = new FlxText(20, 10);
		text.size = 15;
		text.font = "Roboto";
		add(text);


	}

	// freaky...

}
