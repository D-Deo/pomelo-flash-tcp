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

	public class Pomelo extends EventDispatcher
	{
		private var _info:Object;
		private var _handshakeCallback:Function;
		
		private var _socket:Socket;
		
		private var _reqId:int;
		private var _callbacks:Dictionary;
		
		public function Pomelo()
		{
			_info = { sys: { version:"0.0.2a", type:"pomelo-flash-tcp" } };
			_callbacks = new Dictionary(true);
		}
		
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
		
		private function onDecode(e:Event):void
		{
			//TODO: decode data for cache
		}
		
		public function disconnect():void
		{
			_socket.close();
		}
		
		public function request(route:String, msg:Object, callback:Function):void
		{
			if (!route || !route.length) return;
			
			msg = msg || {};
			
			_reqId++;
			send(_reqId, route, msg);
			
			_callbacks[_reqId] = callback;
		}
		
		public function notify(route:String, msg:Object):void
		{
			msg = msg || {};
			send(0, route, msg);
		}
		
		private function send(reqId:int, route:String, msg:Object):void
		{
			var type:int = reqId ? Message.TYPE_REQUEST : Message.TYPE_NOTIFY;
			
			var byte:ByteArray = Protocol.strencode(JSON.stringify(msg));
			
			byte = Message.encode(reqId, type, route, byte);
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
					
					var ack:ByteArray = Package.encode(Package.TYPE_HANDSHAKE_ACK);
					_socket.writeBytes(ack, 0, ack.length);
					_socket.flush();
					
					if (_handshakeCallback) _handshakeCallback.apply(null, [JSON.parse(message)]);
					else dispatchEvent(new Event("handshake"));
					break;
				
				case 2:
					break;
				
				case 3:
					//TODO: server heartbeat package
					break;
				
				case 4:
					var msg:Object = Message.decode(pkg.body);
					if (!msg.id)
					{
						dispatchEvent(new PomeloEvent(msg.route, msg.body));
					}
					else
					{
						(_callbacks[msg.id] as Function).call(this, msg.body);
						_callbacks[msg.id] = null;
						delete _callbacks[msg.id];
					}
					break;
				
				case 5:
					//TODO: server close client
					break;
			}
		}
	}
}

