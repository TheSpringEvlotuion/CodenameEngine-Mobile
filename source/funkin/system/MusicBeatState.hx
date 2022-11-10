package funkin.system;

import funkin.scripting.DummyScript;
import flixel.FlxState;
import flixel.FlxSubState;
import funkin.scripting.events.*;
import funkin.scripting.Script;
import funkin.interfaces.IBeatReceiver;
import funkin.system.Conductor.BPMChangeEvent;
import funkin.system.Conductor;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import funkin.options.PlayerSettings;

class MusicBeatState extends FlxUIState implements IBeatReceiver
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	/**
	 * Whenever the Conductor auto update should be enabled or not.
	 */
	 public var cancelConductorUpdate:Bool = false;

	/**
	 * Current step
	 */
	public var curStep(get, never):Int;
	/**
	 * Current beat
	 */
	public var curBeat(get, never):Int;
	/**
	 * Current step, as a `Float` (ex: 4.94, instead of 4)
	 */
	public var curStepFloat(get, never):Float;
	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public var curBeatFloat(get, never):Float;
	/**
	 * Current song position (in milliseconds).
	 */
	public var songPos(get, never):Float;

	inline function get_curStep():Int
		return Conductor.curStep;
	inline function get_curBeat():Int
		return Conductor.curBeat;
	inline function get_curStepFloat():Float
		return Conductor.curStepFloat;
	inline function get_curBeatFloat():Float
		return Conductor.curBeatFloat;
	inline function get_songPos():Float
		return Conductor.songPosition;

	/**
	 * Game Controls.
	 */
	public var controls(get, never):Controls;

	/**
	 * Current injected script attached to the state. To add one, create a file at path "scripts/stateName" (ex: "scripts/")
	 */
	public var stateScript:Script;

	public var scriptsAllowed:Bool = true;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public function new(scriptsAllowed:Bool = true) {
		super();
		this.scriptsAllowed = scriptsAllowed;
		loadScript();
	}

	function loadScript() {
		if (scriptsAllowed) {
			if (stateScript == null || stateScript is DummyScript) {
				var className = Type.getClassName(Type.getClass(this));
				var scriptName = className.substr(className.lastIndexOf(".")+1);
		
				stateScript = Script.create(Paths.script('data/states/${scriptName}'));
				stateScript.setParent(this);
				stateScript.load();
			} else {
				stateScript.reload();
			}
		}
	}
	override function create()
	{
		super.create();
		call("create");
	}

	public override function createPost() {
		super.createPost();
		call("createPost");
	}
	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script
		if (stateScript == null) return defaultVal;
		return stateScript.call(name, args);
	}

	public function event<T:CancellableEvent>(name:String, event:T):T {
		if (stateScript == null) return event;
		stateScript.call(name, [event]);
		return event;
	}

	override function update(elapsed:Float)
	{
		// TODO: DEBUG MODE!!
		if (FlxG.keys.justPressed.F5) {
			loadScript();
			if (stateScript != null && !(stateScript is DummyScript))
				Logs.trace('State script successfully reloaded', WARNING, GREEN);
		}
		call("update");
		super.update(elapsed);
	}

	@:dox(hide) public function stepHit(curStep:Int):Void
	{
		for(e in members) if (e is IBeatReceiver) cast(e, IBeatReceiver).stepHit(curStep);
		call("stepHit", [curStep]);
	}

	@:dox(hide) public function beatHit(curBeat:Int):Void
	{
		for(e in members) if (e is IBeatReceiver) cast(e, IBeatReceiver).beatHit(curBeat);
		call("beatHit", [curBeat]);
	}

	/**
	 * Shortcut to `FlxMath.lerp` or `CoolUtil.lerp`, depending on `fpsSensitive`
	 * @param v1 Value 1
	 * @param v2 Value 2
	 * @param ratio Ratio
	 * @param fpsSensitive Whenever the ratio should not be adjusted to run at the same speed independant of framerate.
	 */
	public function lerp(v1:Float, v2:Float, ratio:Float, fpsSensitive:Bool = false) {
		if (fpsSensitive)
			return FlxMath.lerp(v1, v2, ratio);
		else
			return CoolUtil.fpsLerp(v1, v2, ratio);
	}

	/**
	 * SCRIPTING STUFF 
	 */
	public override function openSubState(subState:FlxSubState) {
		var e = event("onOpenSubState", new StateEvent(subState));
		if (!e.cancelled)
			super.openSubState(subState);
	}

	public override function onResize(w:Int, h:Int) {
		super.onResize(w, h);
		event("onResize", new ResizeEvent(w, h));
	}

	public override function destroy() {
		super.destroy();
		call("onDestroy");
		stateScript.destroy();
	}

	public override function switchTo(nextState:FlxState) {
		var e = event("onStateSwitch", new StateEvent(nextState));
		if (e.cancelled)
			return false;
		return super.switchTo(nextState);
	}

	public override function onFocus() {
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost() {
		super.onFocusLost();
		call("onFocusLost");
	}
}
