package org.idream.pomelo 
{
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Deo
	 */
	public class Message 
	{
		public static const MSG_FLAG_BYTES:int = 1;
		public static const MSG_ROUTE_CODE_BYTES:int = 2;
		public static const MSG_ID_MAX_BYTES:int = 5;
		public static const MSG_ROUTE_LEN_BYTES:int = 1;
		
		public static const MSG_ROUTE_CODE_MAX:int = 0xffff;
		
		public static const MSG_COMPRESS_ROUTE_MASK:int = 0x1;
		public static const MSG_TYPE_MASK:int = 0x7;
		
		public static const TYPE_REQUEST:int = 0;
		public static const TYPE_NOTIFY:int = 1;
		public static const TYPE_RESPONSE:int = 2;
		public static const TYPE_PUSH:int = 3;
		
		public static function encode(id:int, type:int, route:String, msg:ByteArray):ByteArray
		{
			var byte:ByteArray = new ByteArray();
			byte.writeByte((type << 1) | 0);
			
			if (id)
			{
				var len:Array = [];
				len.push(id & 0x7f);
				id >>= 7;
				while(id > 0)
				{
					len.push(id & 0x7f | 0x80);
					id >>= 7;
				}
				
				for (var i:int = len.length - 1; i >= 0; i--) 
				{
					byte.writeByte(len[i]);
				}
			}
			
			if (route && route.length)
			{
				byte.writeByte(route.length & 0xff);
				byte.writeUTFBytes(route);
			}
			
			if (msg) 
			{
				byte.writeBytes(msg, 0, msg.length);
			}
			
			return byte;
		}
		
		public static function decode(buffer:ByteArray):Object
		{
			// parse flag
			var flag:int = buffer.readUnsignedByte();
			var compressRoute:int = flag & MSG_COMPRESS_ROUTE_MASK;
			var type:int = (flag >> 1) & MSG_TYPE_MASK;
			
			// parse id
			var id:int = 0;
			if (type === Message.TYPE_REQUEST || type === Message.TYPE_RESPONSE) 
			{
				var byte:int = buffer.readUnsignedByte();
				id = byte & 0x7f;
				while(byte & 0x80)
				{
					id <<= 7;
					byte = buffer.readUnsignedByte();
					id |= byte & 0x7f;
				}
			}
			
			// parse route
			if (type === Message.TYPE_REQUEST || type === Message.TYPE_NOTIFY || type === Message.TYPE_PUSH)
			{
				var routeLen:int = buffer.readUnsignedByte();
				var route:String = routeLen ? buffer.readUTFBytes(routeLen) : "";
			}
			
			// parse body
			var body:String = Protocol.strdecode(buffer);
			
			trace(id, type, route, body);
			return { 'id': id, 'type': type, 'compressRoute': compressRoute, 'route': route, 'body': JSON.parse(body) };
		}
		
	}

}