package org.idream.pomelo 
{
	import flash.utils.ByteArray;
	
	import org.idream.pomelo.interfaces.IMessage;
	
	/**
	 * ...
	 * @author Deo
	 */
	public class Message implements IMessage
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
		
		public function Message()
		{
			
		}
		
		public function encode(id:uint, route:String, msg:Object):ByteArray
		{
			var buffer:ByteArray = new ByteArray();
			
			var type:int = id ? Message.TYPE_REQUEST : Message.TYPE_NOTIFY;
			
			var byte:ByteArray = Protobuf.encode(route, msg) || Protocol.strencode(JSON.stringify(msg));
			
			var rot:* = Routedic.getID(route) || route;
			
			buffer.writeByte((type << 1) | ((rot is String) ? 0 : 1));
			
			if (id)
			{
				// 7.x
				do
				{
					var tmp:int = id % 128;
					var next:Number = Math.floor(id / 128);
					
					if (next != 0)
					{
						tmp = tmp + 128;
					}
					
					buffer.writeByte(tmp);
					
					id = next;
				} while (id != 0);
				
				// 5.x
//				var len:Array = [];
//				len.push(id & 0x7f);
//				id >>= 7;
//				while(id > 0)
//				{
//					len.push(id & 0x7f | 0x80);
//					id >>= 7;
//				}
//				
//				for (var i:int = len.length - 1; i >= 0; i--) 
//				{
//					buffer.writeByte(len[i]);
//				}
			}
			
			if (rot)
			{
				if (rot is String)
				{
					buffer.writeByte(rot.length & 0xff);
					buffer.writeUTFBytes(rot);
				}
				else
				{
					buffer.writeByte((rot >> 8) & 0xff);
					buffer.writeByte(rot & 0xff);
				}
			}
			
			if (byte) 
			{
				buffer.writeBytes(byte);
			}
			
			return buffer;
		}
		
		public function decode(buffer:ByteArray):Object
		{
			// parse flag
			var flag:int = buffer.readUnsignedByte();
			var compressRoute:int = flag & MSG_COMPRESS_ROUTE_MASK;
			var type:int = (flag >> 1) & MSG_TYPE_MASK;
			
			// parse id
			var id:int = 0;
			if (type === Message.TYPE_REQUEST || type === Message.TYPE_RESPONSE) 
			{
				// 7.x
				var i:int = 0;
				do
				{
					var m:int = buffer.readUnsignedByte();
					id = id + ((m & 0x7f) * Math.pow(2, (7 * i)));
					i++;
				} while(m >= 128);
				
				// 5.x
//				var byte:int = buffer.readUnsignedByte();
//				id = byte & 0x7f;
//				while(byte & 0x80)
//				{
//					id <<= 7;
//					byte = buffer.readUnsignedByte();
//					id |= byte & 0x7f;
//				}
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
			else if (type === Message.TYPE_RESPONSE)
			{
				route = Pomelo.requests[id].route;
			}
			
			if (!id && !(route is String)) 
			{
				route = Routedic.getName(route);
			}
			
			var body:Object = Protobuf.decode(route, buffer) || JSON.parse(Protocol.strdecode(buffer));
			
			return {id:id, type:type, route:route, body:body};
		}
		
	}

}