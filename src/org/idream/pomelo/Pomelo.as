package org.idream.pomelo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import org.idream.pomelo.interfaces.IMessage;
	import org.idream.pomelo.interfaces.IPackage;
	
	[Event(name="handshake", type="org.idream.pomelo.PomeloEvent")]
	[Event(name="kicked", type = "org.idream.pomelo.PomeloEvent")]
	[Event(name="close", type = "flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	
	/**
	 * Pomelo - Flash - TCP
	 * @author Deo
	 * @version 0.1.6 beta
	 */
	public class Pomelo extends EventDispatcher
	{
		public static const requests:Dictionary = new Dictionary(true);
		public static const info:Object = { sys: { version:"0.1.6b", type:"pomelo-flash-tcp", pomelo_version:"0.7.x" } };
		
		private var _handshake:Function;
		private var _socket:Socket;
		private var _hb:uint;
		
		private var _package:IPackage;
		private var _message:IMessage;
		
		private var _pkg:Object;
		
		private var _useWeakReference:Boolean;
		private var _routesAndCallbacks:Array = new Array();
		
		private static var _pomelo:Pomelo;
		
		public static function getIns():Pomelo
		{
			return _pomelo ||= new Pomelo(false);
		}
		
		public var heartbeat:int;
		
		public function Pomelo(useWeakReference:Boolean = true)
		{
			_package = new Package();
			_message = new Message();
			_useWeakReference = useWeakReference;
			
			trace("[Pomelo] start:", JSON.stringify(info));
		}
		
		/**
		 * 初始化客户端，并尝试连接服务器
		 * @param host
		 * @param port
		 * @param user 客户端与服务器之间的自定义数据
		 * @param callback 当连接成功会调用此方法
		 * @param timeout 连接超时
		 * @param cross 安全策略文件的自定义端口
		 */
		public function init(host:String, port:int, user:Object = null, callback:Function = null, timeout:int = 8000, cross:int = 3843):void
		{
			info.user = user;
			
			_handshake = callback;
			
//			trace("[Pomelo] load policy file:", "xmlsocket://" + host + ":3843");
			Security.loadPolicyFile("xmlsocket://" + host + ":" + cross);
			
			if (!_socket)
			{
				_socket = new Socket();
				_socket.timeout = timeout;
				_socket.addEventListener(Event.CONNECT, onConnect, false, 0, _useWeakReference);
				_socket.addEventListener(Event.CLOSE, onClose, false, 0, _useWeakReference);
				_socket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutputProgress, false, 0, _useWeakReference);
				_socket.addEventListener(ProgressEvent.SOCKET_DATA, onData, false, 0, _useWeakReference);
				_socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, _useWeakReference);
				_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, _useWeakReference);
			}
			
			trace("[Pomelo] start to connect server ...");
			_socket.connect(host, port);
		}
		
		/**
		 * 与服务器主动断开连接
		 */
		public function disconnect():void
		{
			trace("[Pomelo] client close ...");
			if (_socket && _socket.connected) _socket.close();
			if (_hb) clearTimeout(_hb);
		}
		
		/**
		 * 向服务器请求数据
		 * @param route
		 * @param msg
		 * @param callback 服务器返回数据时会回调
		 */
		public function request(route:String, msg:Object, callback:Function = null):void
		{
			if (!route || !route.length) return;
			
			if (callback == null) 
			{
				this.notify(route, msg);
				return;
			}
			
			var req:Request = new Request(route, callback);
			requests[req.id] = req;
			
			send(req.id, req.route, msg || {});
		}
		
		/**
		 * 向服务器发送数据
		 * @param route
		 * @param msg
		 */
		public function notify(route:String, msg:Object):void
		{
			send(0, route, msg || {});
		}
		
		/**
		 * 响应服务器的推送事件
		 * @param route 推送事件的名称
		 * @param callback 当服务器发生推送时会调用此函数
		 */
		public function on(route:String, callback:Function):void
		{
			this.addEventListener(route, callback, false, 0, _useWeakReference);
			_routesAndCallbacks.push([route, callback]);
		}
		
		/**
		 * 向服务器发送一次心跳事件
		 */
		public function beat():void
		{
			clearTimeout(_hb);
			_hb = 0;
			
			if (_socket && _socket.connected)
			{
				_socket.writeBytes(_package.encode(Package.TYPE_HEARTBEAT));
				_socket.flush();
			}
		}
		
		private function send(reqId:int, route:String, msg:Object):void
		{
			trace("[Pomelo] send msg: ", JSON.stringify(msg));
			
			var byte:ByteArray;
			
			byte = _message.encode(reqId, route, msg);
			byte = _package.encode(Package.TYPE_DATA, byte);
			
			if (_socket && _socket.connected)
			{
				_socket.writeBytes(byte);
				_socket.flush();
			}
		}
		
		private function onConnect(e:Event):void
		{
			trace("[Pomelo] connect success ...");
			_socket.writeBytes(_package.encode(Package.TYPE_HANDSHAKE, Protocol.strencode(JSON.stringify(info))));
			_socket.flush();
		}
		
		private function onOutputProgress(e:OutputProgressEvent):void
		{
			trace("[Pomelo] flush ...");
		}
		
		private function onClose(e:Event):void
		{
			trace("[Pomelo] connect close ...");
			this.dispatchEvent(e);
		}
		
		private function onIOError(e:IOErrorEvent):void
		{
			trace("[Pomelo] ", e);
			this.dispatchEvent(e);
		}
		
		private function onSecurityError(e:SecurityErrorEvent):void
		{
			trace("[Pomelo] ", e);
			this.dispatchEvent(e);
		}
		
		private function onData(e:ProgressEvent):void
		{
			trace("[Pomelo] client received:", _socket.bytesAvailable);
			
			do
			{
				if (_pkg)
				{
					if (_socket.bytesAvailable >= _pkg.length)
					{
						_pkg.body = new ByteArray();
						if (_pkg.length) _socket.readBytes(_pkg.body, 0, _pkg.length);
					}
				}
				else
				{
					_pkg = _package.decode(_socket);
				}
				
				trace("[Package] type:", _pkg.type, "length:", _pkg.length);
				
				if (_pkg.body)
				{
					switch(_pkg.type)
					{
						case Package.TYPE_HANDSHAKE:
							var message:String = _pkg.body.readUTFBytes(_pkg.body.length);
							trace("[Handshake] message:", message);
							
							var response:Object = JSON.parse(message);
							
							if (response.code == 200)
							{
								if (response.sys) 
								{
									Routedic.init(response.sys.dict);
									Protobuf.init(response.sys.protos);
									
									this.heartbeat = response.sys.heartbeat;
								}
								
								_socket.writeBytes(_package.encode(Package.TYPE_HANDSHAKE_ACK));
								_socket.flush();
								
								this.dispatchEvent(new PomeloEvent(PomeloEvent.HANDSHAKE));
							}
							
							if (_handshake != null) _handshake.call(this, response);
							
							_pkg = null;
							break;
						
						case Package.TYPE_HANDSHAKE_ACK:
							_pkg = null;
							break;
						
						case Package.TYPE_HEARTBEAT:
							_pkg = null;
							
							if (this.heartbeat)
							{
								_hb = setTimeout(beat, this.heartbeat * 1000);
							}
							break;
						
						case Package.TYPE_DATA:
							var msg:Object = _message.decode(_pkg.body);
							
							trace("[Message] route:", msg.route, "body:", JSON.stringify(msg.body));
							
							if (!msg.id)
							{
								this.dispatchEvent(new PomeloEvent(msg.route, msg.body));
							}
							else
							{
								requests[msg.id].callback.call(this, msg.body);
								requests[msg.id] = null;
							}
							
							_pkg = null;
							break;
						
						case Package.TYPE_KICK:
							this.dispatchEvent(new PomeloEvent(PomeloEvent.KICKED));
							_pkg = null;
							break;
					}
				}
				
				if (_socket)
				    trace("[Pomelo] client next:", _socket.bytesAvailable);
			}
			while (!_pkg && _socket && _socket.bytesAvailable > 4);
		}

		public function get message():IMessage
		{
			return _message;
		}

		public function set message(value:IMessage):void
		{
			_message = value;
		}
		
		/**
		* if you use new Pomelo(false)
		* (not using weak reference)
		* don't forget to call destroy()
		*/
		public function destroy():void
		{
			for (var r:int=_routesAndCallbacks.length-1;r>=0;r--)
			{
				this.removeEventListener(_routesAndCallbacks[r][0], _routesAndCallbacks[r][1]);
			}
			
			_socket.removeEventListener(Event.CONNECT, onConnect);
			_socket.removeEventListener(Event.CLOSE, onClose);
			_socket.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutputProgress);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onData);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
		}
	}
}

