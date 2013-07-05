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
		
		public static function encode(id:int, type:int, route:*, msg:ByteArray):ByteArray
		{
			var byte:ByteArray = new ByteArray();
			byte.writeByte((type << 1) | ((route is String) ? 0 : 1));
			
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
			
			if (route)
			{
				if (route is String)
				{
					byte.writeByte(route.length & 0xff);
					byte.writeUTFBytes(route);
				}
				else
				{
					byte.writeByte((route >> 8) & 0xff);
					byte.writeByte(route & 0xff);
				}
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
				var route:*;
				
				if (compressRoute)
				{
					route = buffer.readUnsignedShort();
				}
				else
				{
					var routeLen:int = buffer.readUnsignedByte();
					route = routeLen ? buffer.readUTFBytes(routeLen) : "";
				}
			}
			
			// parse body
//			var body:String = Protocol.strdecode(buffer);
			
			trace(id, type, compressRoute, route);
			return { 'id': id, 'type': type, 'compressRoute': compressRoute, 'route': route, 'body': buffer };
		}
		
	}

}