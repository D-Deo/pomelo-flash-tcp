package org.idream.pomelo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import org.idream.pomelo.interfaces.IMessage;
	import org.idream.pomelo.interfaces.IPackage;

	/**
	 * Pomelo - Flash - TCP
	 * @author Deo
	 * @version 0.1.0 beta
	 */
	public class Pomelo extends EventDispatcher
	{
		public static const requests:Dictionary = new Dictionary(true);
		public static const info:Object = { sys: { version:"0.1.0b", type:"pomelo-flash-tcp", pomelo_version:"0.5.x" } };
		
		private var _handshake:Function;
		private var _socket:Socket;
		
		private var _package:IPackage;
		private var _message:IMessage;
		
		private var _pkg:Object;
		
		private static var _pomelo:Pomelo;
		
		public static function getIns():Pomelo
		{
			return _pomelo ||= new Pomelo();
		}
		
		public function Pomelo()
		{
			_package = new Package();
			_message = new Message();
			
			trace("[Pomelo] start:", JSON.stringify(info));
		}
		
		/**
		 * 初始化客户端，并尝试连接服务器
		 * @param host
		 * @param port
		 * @param user 客户端与服务器之间的自定义数据
		 * @param callback 当连接成功会调用此方法
		 */
		public function init(host:String, port:int, user:Object = null, callback:Function = null):void
		{
			info.user = user;
			
			_handshake = callback;
			
			_socket = new Socket();
			_socket.addEventListener(Event.CONNECT, onConnect, false, 0, true);
			_socket.addEventListener(Event.CLOSE, onClose, false, 0, true);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onData, false, 0, true);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true);
			
			_socket.connect(host, port);
			
			function onConnect(e:Event):void
			{
				trace("[Pomelo] connect success ...");
				_socket.writeBytes(_package.encode(Package.TYPE_HANDSHAKE, Protocol.strencode(JSON.stringify(info))));
				_socket.flush();
			}
			
			function onClose(e:Event):void
			{
				trace("[Pomelo] connect close ...");
				_socket = null;
				dispatchEvent(e);
			}
			
			function onIOError(e:IOErrorEvent):void
			{
				trace("[Pomelo] ", e);
				_socket = null;
				dispatchEvent(e);
			}
			
			function onSecurityError(e:SecurityErrorEvent):void
			{
				trace("[Pomelo] ", e);
				_socket = null;
				dispatchEvent(e);
			}
		}
		
		/**
		 * 与服务器主动断开连接
		 */
		public function disconnect():void
		{
			trace("[Pomelo] client close ...");
			_socket.close();
			_socket = null;
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
			this.addEventListener(route, callback);
		}
		
		private function send(reqId:int, route:String, msg:Object):void
		{
			var byte:ByteArray;
			
			byte = _message.encode(reqId, route, msg);
			byte = _package.encode(Package.TYPE_DATA, byte);
			
			_socket.writeBytes(byte);
			_socket.flush();
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
						_socket.readBytes(_pkg.body, 0, _pkg.length);
					}
				}
				else
				{
					_pkg = _package.decode(_socket);
				}
				
				trace("[Package] type:", _pkg.type);
				
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
								}
								
								_socket.writeBytes(_package.encode(Package.TYPE_HANDSHAKE_ACK));
								_socket.flush();
								
								this.dispatchEvent(new Event("handshake"));
							}
							
							if (_handshake != null) _handshake.call(this, response);
							
							_pkg = null;
							break;
						
						case Package.TYPE_HANDSHAKE_ACK:
							_pkg = null;
							break;
						
						case Package.TYPE_HEARTBEAT:
							//TODO: server heartbeat package
							_pkg = null;
							break;
						
						case Package.TYPE_DATA:
							var msg:Object = _message.decode(_pkg.body);
							
							trace("[Message] body:", JSON.stringify(msg.body));
							
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
							//TODO: server close client
							_pkg = null;
							break;
					}
				}
			}
			while (!_pkg && _socket.bytesAvailable > 4);
		}

		public function get message():IMessage
		{
			return _message;
		}

		public function set message(value:IMessage):void
		{
			_message = value;
		}
	}
}

