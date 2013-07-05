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
	
	import org.idream.pomelo.Message;
	import org.idream.pomelo.Package;
	import org.idream.pomelo.Protocol;

	/**
	 * Pomelo
	 * @author Deo
	 * @version v0.0.3a
	 */
	public class Pomelo extends EventDispatcher
	{
		private var _sys:Object = {};
		private var _info:Object;
		private var _handshakeCallback:Function;
		
		private var _socket:Socket;
		
		private var _reqId:int;
		private var _requestDict:Dictionary;
		private var _routeDict:Dictionary;
		
		public function Pomelo()
		{
			_info = { sys: { version:"0.0.3a", type:"pomelo-flash-tcp" } };
			_requestDict = new Dictionary(true);
			_routeDict = new Dictionary(true);
		}
		
		/**
		 * 初始化客户端，并尝试连接服务器
		 * @param host
		 * @param port
		 * @param user 客户端与服务器之间的自定义数据
		 * @param handshakeCallback 当连接成功会调用此方法
		 */
		public function init(host:String, port:int, user:Object = null, handshakeCallback:Function = null):void
		{
			_info.user = user;
			_handshakeCallback = handshakeCallback;
			
			_socket = new Socket();
			_socket.addEventListener(Event.CONNECT, onConnect, false, 0, true);
			_socket.addEventListener(Event.CLOSE, onClose, false, 0, true);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onData, false, 0, true);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true);
			
			//this.addEventListener(Event.ENTER_FRAME, onDecode);
			
			_socket.connect(host, port);
			
			function onConnect(e:Event):void
			{
				trace("connect success ...");
				
				var bytes:ByteArray = Package.encode(Package.TYPE_HANDSHAKE, Protocol.strencode(JSON.stringify(_info)));
				_socket.writeBytes(bytes, 0, bytes.length);
				_socket.flush();
			}
			
			function onClose(e:Event):void
			{
				trace("connect close ...");
				
				_socket.removeEventListener(Event.CONNECT, onConnect);
				_socket.removeEventListener(Event.CLOSE, onClose);
				_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onData);
				_socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_socket = null;
				
				dispatchEvent(e);
			}
			
			function onIOError(e:IOErrorEvent):void
			{
				trace(e);
				dispatchEvent(e);
			}
			
			function onSecurityError(e:SecurityErrorEvent):void
			{
				trace(e);
				dispatchEvent(e);
			}
		}
		
//		private function onDecode(e:Event):void
//		{
//			
//		}
		
		/**
		 * 与服务器主动断开连接
		 */
		public function disconnect():void
		{
			_socket.close();
			_socket = null;
		}
		
		/**
		 * 向服务器请求数据
		 * @param route
		 * @param msg
		 * @param callback 服务器返回数据时会回调
		 */
		public function request(route:String, msg:Object, callback:Function):void
		{
			if (!route || !route.length) return;
			
			msg = msg || {};
			
			_reqId++;
			send(_reqId, route, msg);
			
			_requestDict[_reqId] = {'route': route, 'callback': callback};
		}
		
		/**
		 * 向服务器发送数据
		 * @param route
		 * @param msg
		 */
		public function notify(route:String, msg:Object):void
		{
			msg = msg || {};
			send(0, route, msg);
		}
		
		private function send(reqId:int, route:String, msg:Object):void
		{
			var type:int = reqId ? Message.TYPE_REQUEST : Message.TYPE_NOTIFY;
			
			var byte:ByteArray = Protocol.strencode(JSON.stringify(msg));
			
			byte = Message.encode(reqId, type, _sys.dict ? _sys.dict[route] : route, byte);
			byte = Package.encode(Package.TYPE_DATA, byte);
			
			_socket.writeBytes(byte, 0, byte.length);
			_socket.flush();
		}
		
		private function onData(e:ProgressEvent):void
		{
			trace("data received ...");
			var byte:ByteArray = new ByteArray();
			_socket.readBytes(byte, 0, _socket.bytesAvailable);
			
			var pkg:Object = Package.decode(byte);
			trace(pkg.type);
			
			switch(pkg.type)
			{
				case 1:
					var message:String = pkg.body.readUTFBytes(pkg.body.length);
					trace(message);
					var response:Object = JSON.parse(message);
					
					if (response.code == 200)
					{
						if (response.sys) 
						{
							_sys = response.sys;
							for (var key:String in _sys.dict)
							{
								_routeDict[_sys.dict[key]] = key;
							}
						}
						
						var ack:ByteArray = Package.encode(Package.TYPE_HANDSHAKE_ACK);
						_socket.writeBytes(ack, 0, ack.length);
						_socket.flush();
					}
					
					if (_handshakeCallback != null) _handshakeCallback.call(this, response);
					else dispatchEvent(new Event("handshake"));
					break;
				
				case 2:
					break;
				
				case 3:
					//TODO: server heartbeat package
					break;
				
				case 4:
					var msg:Object = Message.decode(pkg.body);
					
					if (!msg.id && !(msg.route is String)) 
					{
						msg.route = _routeDict[msg.route];
					}
					else if (msg.id && !msg.route) 
					{
						msg.route = _requestDict[msg.id].route;
					}
					
					if (_sys.protos && _sys.protos.server && _sys.protos.server[msg.route])
					{
						msg.body = Protobuf.decode(_sys.protos.server[msg.route], msg.body);
					}
					else
					{
						msg.body = JSON.parse(Protocol.strdecode(msg.body));
					}
					
					if (!msg.id)
					{
						dispatchEvent(new PomeloEvent(msg.route, msg.body));
					}
					else
					{
						_requestDict[msg.id].callback.call(this, msg.body);
						_requestDict[msg.id] = null;
						delete _requestDict[msg.id];
					}
					break;
				
				case 5:
					//TODO: server close client
					break;
			}
		}
	}
}

