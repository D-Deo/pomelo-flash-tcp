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
		private static const CLIENT_INFO:String = "{'sys': {'version': '0.0.1', +'type': 'falsh-socket' +}, 'user': {}}";
		
		private var _user:Object;
		private var _socket:Socket;
		
		private var _reqId:int;
		private var _callbacks:Dictionary;
		
		public function Pomelo()
		{
			_user = { sys: { version:"0.0.1", type:"flash-socket" }, user: { }};
			_callbacks = new Dictionary(true);
		}
		
		/**
		 * connect to server
		 * @param	params		{host:String, port:int, user:Object = null, handshakeCallback:Function = null}
		 * @param	callback
		 */
		public function init(params:Object, callback:Function = null):void
		{
			_socket = new Socket();
			_socket.addEventListener(Event.CONNECT, onConnect, false, 0, true);
			_socket.addEventListener(Event.CLOSE, onClose, false, 0, true);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onData, false, 0, true);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true);
			
			//this.addEventListener(Event.ENTER_FRAME, onDecode);
			
			_socket.connect(params.host, params.port);
			
			function onConnect(e:Event):void
			{
				trace("success ...");
				var bytes:ByteArray = Package.encode(Package.TYPE_HANDSHAKE, Protocol.strencode(JSON.stringify(_user)));
				_socket.writeBytes(bytes, 0, bytes.length);
				_socket.flush();
				trace("handshake ...");
				
				//dispatchEvent(e);//
			}
			
			function onClose(e:Event):void
			{
				trace("close ...");
				
				_socket.removeEventListener(Event.CONNECT, onConnect);
				_socket.removeEventListener(Event.CLOSE, onClose);
				_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onData);
				_socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_socket = null;
				
//				SvnList.NetWork=2//连接关闭
				
				dispatchEvent(e);
			}
			
			function onIOError(e:IOErrorEvent):void
			{
				trace("io error ...");
//				SvnList.NetWork=3//服务器断开连接
				_socket.connect("124.14.7.135", 3010);
			}
			
			function onSecurityError(e:SecurityErrorEvent):void
			{
				trace("security error ...");
//				SvnList.NetWork=3//服务器断开连接
			}
		}
		
		private function onDecode(e:Event):void
		{
			
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
					trace("handshake ack ...");
					
//					SvnList.NetWork=1//连接成功
					dispatchEvent(new Event("handshake"));
					break;
				
				case 2:
					break;
				
				case 3:
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
					break;
			}
		}
	}
}

