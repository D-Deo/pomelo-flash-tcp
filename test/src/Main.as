package 
{
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import org.idream.pomelo.Pomelo;
	import org.idream.pomelo.PomeloEvent;
	
	/**
	 * ...
	 * @author Deo
	 */
	public class Main extends Sprite 
	{
		private static const PLAYER_IDLE:int = 0x1000;
		private static const PLAYER_READY:int = 0x1001;
		private static const PLAYER_START:int = 0x1002;
		
		private var _pomelo:Pomelo;
		private var _player:Object;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// init events
			_pomelo = new Pomelo();
			_pomelo.addEventListener("onReady", function(e:PomeloEvent):void {
				
			});
			_pomelo.addEventListener("onStart", function(e:PomeloEvent):void {
				
			});
			
			// connect
			var connect:Sprite = createButton("connect", 100, 100);
			connect.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
//				_pomelo.init( { 'host':"10.192.247.24", 'port':3010 } );
//				_pomelo.init({host:"192.168.1.102", port:"3010"});
				_pomelo.init("127.0.0.1", 3014, null, function(msg:Object):void {
					if (msg.code == 200)
					{
						trace(msg.user.message);
						
						_pomelo.request("gate.gateHandler.entry", {uid:1}, function(response:Object):void {
							if (response.code == 200) 
							{
								trace(response.host, response.port);
								_pomelo.disconnect();
								_pomelo.init(response.host, response.port, null, function(msg:Object):void {
									trace("connect logic success...");
								});
							}
							else trace(response.code);
						});
					}
				});
			});
			
			// login
			var login:Sprite = createButton("login", 200, 100);
			login.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_pomelo.request("connector.loginHandler.connect", { playerId:211 }, function(response:Object):void {
					trace(response.player);
					_player = response.player;
				});
			});
//			
//			// start
//			var start:Sprite = createButton("start", 300, 100);
//			start.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
//				_pomelo.request("connector.playerHandler.selectRoom", { roomMid:1 }, function(response:Object):void {
//					trace(response.room);
//				});
//			});
//			
//			// ready
//			var ready:Sprite = createButton("ready", 400, 100);
//			ready.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
//				if (_player.state == PLAYER_IDLE)
//				{
//					_pomelo.notify("connector.playerHandler.ready", null);
//				}
//			});
		}
		
		public function createButton(text:String = null, x:Number = 0, y:Number = 0, added:Boolean = true):Sprite
		{
			var sprite:Sprite = new Sprite();
			
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xFF8080);
			shape.graphics.drawRect(0, 0, 60, 30);
			shape.graphics.endFill();
			
			var button:SimpleButton = new SimpleButton(shape, shape, shape, shape);
			button.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				parent.dispatchEvent(e);
			});
			var label:TextField = new TextField();
			label.mouseEnabled = false;
			label.width = button.width;
			if (text) label.text = text;
			
			sprite.addChild(button);
			sprite.addChild(label);
			sprite.x = x;
			sprite.y = y;
			if (added) this.addChild(sprite);
			
			return sprite;
		}
	}
	
}