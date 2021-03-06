package flixel.system.debug;

#if !FLX_NO_DEBUG

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;
import flixel.FlxG;
import flixel.system.debug.Console;
import flixel.system.debug.Log;
import flixel.system.debug.Stats;
import flixel.system.debug.VCR;
import flixel.system.debug.Vis;
import flixel.system.debug.Watch;
import flixel.system.FlxAssets;

/**
 * Container for the new debugger overlay.
 * Most of the functionality is in the debug folder widgets,
 * but this class instantiates the widgets and handles their basic formatting and arrangement.
 */
class FlxDebugger extends Sprite
{
	/**
	 * Debugger overlay layout preset: Wide but low windows at the bottom of the screen.
	 */
	inline static public var STANDARD:Int = 0;
	
	/**
	 * Debugger overlay layout preset: Tiny windows in the screen corners.
	 */
	inline static public var MICRO:Int = 1;
	
	/**
	 * Debugger overlay layout preset: Large windows taking up bottom half of screen.
	 */
	inline static public var BIG:Int = 2;
	
	/**
	 * Debugger overlay layout preset: Wide but low windows at the top of the screen.
	 */
	inline static public var TOP:Int = 3;
	
	/**
	 * Debugger overlay layout preset: Large windows taking up left third of screen.
	 */
	inline static public var LEFT:Int = 4;
	
	/**
	 * Debugger overlay layout preset: Large windows taking up right third of screen.
	 */
	inline static public var RIGHT:Int = 5;

	/**
	 * Internal, used to space out windows from the edges.
	 */
	inline static public var GUTTER:Int = 2;
	/**
	 * Internal, used to space out windows from the edges.
	 */
	inline static public var TOP_HEIGHT:Int = 18;
	
	/**
	 * Container for the performance monitor widget.
	 */
	public var stats:Stats;
	/**
	 * Container for the bitmap output widget
	 */
	public var bmpLog:BmpLog;	
	/**
	 * Container for the trace output widget.
	 */	 
	public var log:Log;
	/**
	 * Container for the watch window widget.
	 */
	public var watch:Watch;
	/**
	 * Container for the record, stop and play buttons.
	 */
	public var vcr:VCR;
	/**
	 * Container for the visual debug mode toggle.
	 */
	public var vis:Vis;
	/**
	 * Container for console.
	 */
	public var console:Console;
	/**
	 * Whether the mouse is currently over one of the debugger windows or not.
	 */
	public var hasMouse:Bool;
	
	/**
	 * Internal, tracks what debugger window layout user has currently selected.
	 */
	private var _layout:Int;
	/**
	 * Internal, stores width and height of the Flash Player window.
	 */
	private var _screen:Point;
	/**
	 * Stores the bounds in which the windows can move.
	 */
	private var _screenBounds:Rectangle;
	
	/**
	 * Instantiates the debugger overlay.
	 * 
	 * @param 	Width	The width of the screen.
	 * @param 	Height	The height of the screen.
	 */
	public function new(Width:Float, Height:Float)
	{
		super();
		visible = false;
		hasMouse = false;
		_screen = new Point();
		
		#if (flash || js)
		addChild(new Bitmap(new BitmapData(Std.int(Width), TOP_HEIGHT, true, Window.TOP_COLOR)));
		#else
		var bg:Sprite = new Sprite();
		bg.graphics.beginFill(0x000000, 0x7f / 255);
		bg.graphics.drawRect(0, 0, Std.int(Width), 15);
		bg.graphics.endFill();
		addChild(bg);
		#end
		
		var txt:TextField = new TextField();
		txt.x = 3;
		txt.width = 200;
		txt.height = 20;
		txt.selectable = false;
		txt.multiline = false;
		txt.embedFonts = true;
		txt.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEBUGGER, 12, 0xffffff);
		var str:String = FlxG.libraryName;
		txt.text = str;
		addChild(txt);
					
		log = new Log("log", 0, 0, true);
		addChild(log);
		
		watch = new Watch("watch", 0, 0, true);
		addChild(watch);
		
		console = new Console("console", 0, 0, false);
		addChild(console);
		
		stats = new Stats("stats", 0, 0, false);
		addChild(stats);

		#if FLX_BMP_DEBUG
			bmpLog = new BmpLog("bmplog", 0, 0, true);
			addChild(bmpLog);
		#end
		
		vcr = new VCR();
		vcr.x = (Width - vcr.width / 2) / 2;
		vcr.y = 2;
		addChild(vcr);
		
		vis = new Vis();
		vis.x = Width - vis.width - 4;
		vis.y = 2;
		addChild(vis);
		
		onResize(Width, Height);
		
		//Should help with fake mouse focus type behavior
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		_screen = null;
		if (bmpLog != null) 
		{
			removeChild(bmpLog);
			bmpLog.destroy();
			bmpLog = null;
		}		
		if (log != null)
		{
			removeChild(log);
			log.destroy();
			log = null;
		}
		if (watch != null)
		{
			removeChild(watch);
			watch.destroy();
			watch = null;
		}
		if (stats != null)
		{
			removeChild(stats);
			stats.destroy();
			stats = null;
		}
		if (vcr != null)
		{
			removeChild(vcr);
			vcr.destroy();
			vcr = null;
		}
		if (vis != null)
		{
			removeChild(vis);
			vis.destroy();
			vis = null;
		}
		if (console != null) 
		{
			removeChild(console);
			console.destroy();
			console = null;
		}
		
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	/**
	 * Mouse handler that helps with fake "mouse focus" type behavior.
	 * @param	E	Flash mouse event.
	 */
	private function onMouseOver(?E:MouseEvent):Void
	{
		hasMouse = true;
		
		#if !FLX_NO_MOUSE
		FlxG.mouse.useSystemCursor = true;
		#end
	}
	
	/**
	 * Mouse handler that helps with fake "mouse focus" type behavior.
	 * @param	E	Flash mouse event.
	 */
	private function onMouseOut(?E:MouseEvent):Void
	{
		hasMouse = false;
		
		#if !FLX_NO_MOUSE
		if(!FlxG.game.debugger.vcr.paused)
			FlxG.mouse.useSystemCursor = false;
		#end
	}
	
	/**
	 * Change the way the debugger's windows are laid out.
	 * 
	 * @param	Layout	The layout codes can be found in <code>FlxDebugger</code>, for example <code>FlxDebugger.MICRO</code>
	 */
	public function setLayout(Layout:Int):Void
	{
		_layout = Layout;
		resetLayout();
	}
	
	/**
	 * Forces the debugger windows to reset to the last specified layout.
	 * The default layout is <code>STANDARD</code>.
	 */
	public function resetLayout():Void
	{
		switch(_layout)
		{
			case MICRO:
				log.resize(_screen.x / 4, 68);
				log.reposition(0, _screen.y);
				console.resize((_screen.x / 2) - GUTTER * 4, 35);
				console.reposition(log.x + log.width + GUTTER, _screen.y);
				watch.resize(_screen.x / 4, 68);
				watch.reposition(_screen.x,_screen.y);
				stats.reposition(_screen.x, 0);
			case BIG:
				console.resize(_screen.x - GUTTER * 2, 35);
				console.reposition(GUTTER, _screen.y);
				log.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 2);
				log.reposition(0, _screen.y - log.height - console.height - GUTTER * 1.5);
				watch.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 2);
				watch.reposition(_screen.x, _screen.y - watch.height - console.height - GUTTER * 1.5);
				stats.reposition(_screen.x, 0);
			case TOP:
				console.resize(_screen.x - GUTTER * 2, 35);
				console.reposition(0,0);
				log.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
				log.reposition(0,console.height + GUTTER + 15);
				watch.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
				watch.reposition(_screen.x,console.height + GUTTER + 15);
				stats.reposition(_screen.x,_screen.y);
			case LEFT:
				console.resize(_screen.x - GUTTER * 2, 35);
				console.reposition(GUTTER, _screen.y);
				log.resize(_screen.x / 3, (_screen.y - 15 - GUTTER * 2.5) / 2 - console.height / 2 - GUTTER);
				log.reposition(0,0);
				watch.resize(_screen.x / 3, (_screen.y - 15 - GUTTER * 2.5) / 2 - console.height / 2);
				watch.reposition(0,log.y + log.height + GUTTER);
				stats.reposition(_screen.x,0);
			case RIGHT:
				console.resize(_screen.x - GUTTER * 2, 35);
				console.reposition(GUTTER, _screen.y);
				log.resize(_screen.x / 3, (_screen.y - 15 - GUTTER * 2.5) / 2 - console.height / 2 - GUTTER);
				log.reposition(_screen.x,0);
				watch.resize(_screen.x / 3, (_screen.y - 15 - GUTTER * 2.5) / 2 - console.height / 2);
				watch.reposition(_screen.x,log.y + log.height + GUTTER);
				stats.reposition(0,0);
			case STANDARD:
				console.resize(_screen.x - GUTTER * 2, 35);
				console.reposition(GUTTER, _screen.y);
				log.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
				log.reposition(0,_screen.y - log.height - console.height - GUTTER * 1.5);
				watch.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
				watch.reposition(_screen.x,_screen.y - watch.height - console.height - GUTTER * 1.5);
				stats.reposition(_screen.x, 0);
				if (bmpLog != null) {
					bmpLog.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
					bmpLog.reposition(_screen.x, _screen.y - watch.height - bmpLog.height - console.height - GUTTER * 1.5);
				}
			default:
				console.resize(_screen.x - GUTTER * 2, 35);
				console.reposition(GUTTER, _screen.y);
				log.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
				log.reposition(0,_screen.y - log.height - console.height - GUTTER * 1.5);
				watch.resize((_screen.x - GUTTER * 3) / 2, _screen.y / 4);
				watch.reposition(_screen.x,_screen.y - watch.height - console.height - GUTTER * 1.5);
				stats.reposition(_screen.x, 0);				
		}
	}
	
	inline public function onResize(Width:Float, Height:Float):Void
	{
		_screen.x = Width;
		_screen.y = Height;
		_screenBounds = new Rectangle(GUTTER, TOP_HEIGHT + GUTTER / 2, _screen.x - GUTTER * 2, _screen.y - GUTTER * 2 - TOP_HEIGHT);
		stats.updateBounds(_screenBounds);
		log.updateBounds(_screenBounds);
		watch.updateBounds(_screenBounds);
		console.updateBounds(_screenBounds);
		if (bmpLog != null) {
			bmpLog.updateBounds(_screenBounds);
		}
		resetLayout();
	}
}
#end
