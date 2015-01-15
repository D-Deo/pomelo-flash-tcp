package org.idream.pomelo
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class Protobuf
	{
		private static const TYPES:Object = 
		{
			uInt32 : 0,
			sInt32 : 0,
			int32 : 0,
			double : 1,
			string : 2,
			message : 2,
			float : 5
		};
		
		private static var _clients:Object = {};
		private static var _servers:Object = {};
		
		public static function init(protos:Object):void
		{
			_clients = protos && protos.client || {};
			_servers = protos && protos.server || {};
		}
		
		public static function encode(route:String, msg:Object):ByteArray
		{
			var protos:Object = _clients[route];
			
			if (!protos) return null;
			
			return encodeProtos(protos, msg);
		}
		
		public static function decode(route:String, buffer:ByteArray):Object
		{
			var protos:Object = _servers[route];
			
			if (!protos) return null;
			
			return decodeProtos(protos, buffer);
		}
		
		private static function encodeProtos(protos:Object, msg:Object):ByteArray
		{
			var buffer:ByteArray = new ByteArray();
			
			for (var name:* in msg)
			{
				if (protos[name])
				{
					var proto:Object = protos[name];
					
					switch (proto.option)
					{
						case "optional":
						case "required":
							buffer.writeBytes(encodeTag(proto.type, proto.tag));
							encodeProp(msg[name], proto.type, protos, buffer);
							break;
						case "repeated":
							if (!!msg[name] && msg[name].length > 0)
							{
								encodeArray(msg[name], proto, protos, buffer);
							}
							break;
					}
				}
			}
			
			return buffer;
		}
		
		private static function decodeProtos(protos:Object, buffer:ByteArray):Object
		{
			var msg:Object = {};
			
			while(buffer.bytesAvailable)
			{
				var head:Object = getHead(buffer);
				var name:String = protos.__tags[head.tag];
				
				switch (protos[name].option)
				{
					case "optional":
					case "required":
						msg[name] = decodeProp(protos[name].type, protos, buffer);
						break;
					case "repeated":
						if (!msg[name])
						{
							msg[name] = [];
						}
						decodeArray(msg[name], protos[name].type, protos, buffer);
						break;
				}
			}
			
			return msg;
		}
		
		private static function encodeTag(type:int, tag:int):ByteArray
		{
			var value:int = TYPES[type] != undefined ? TYPES[type] : 2;
			
			return encodeUInt32((tag << 3) | value);
		}
		
		private static function getHead(buffer:ByteArray):Object
		{
			var tag:int = decodeUInt32(buffer);
			
			return { type: tag & 0x7, tag: tag >> 3 };
		}
		
		private static function encodeProp(value:*, type:String, protos:Object, buffer:ByteArray):void
		{
			switch(type)
			{
				case 'uInt32':
					buffer.writeBytes(encodeUInt32(value));
					break;
				case 'int32':
				case 'sInt32':
					buffer.writeBytes(encodeSInt32(value));
					break;
				case 'float':
					var floats:ByteArray = new ByteArray();
					floats.endian = Endian.LITTLE_ENDIAN;
					floats.writeFloat(value);
					buffer.writeBytes(floats);
					break;
				case 'double':
					var doubles:ByteArray = new ByteArray();
					doubles.endian = Endian.LITTLE_ENDIAN;
					doubles.writeDouble(value);
					buffer.writeBytes(doubles);
					break;
				case 'string':
					buffer.writeBytes(encodeUInt32(value.length));
					buffer.writeUTFBytes(value);
					break;
				default:
					var proto:Object = protos.__messages[type] || _clients["message " + type];
					if (!!proto)
					{
						var buf:ByteArray = encodeProtos(proto, value);
						buffer.writeBytes(encodeUInt32(buf.length));
						buffer.writeBytes(buf);
					}
					break;
			}
		}
		
		private static function decodeProp(type:String, protos:Object, buffer:ByteArray):*
		{
			switch(type)
			{
				case 'uInt32':
					return decodeUInt32(buffer);
				case 'int32':
				case 'sInt32':
					return decodeSInt32(buffer);
				case 'float':
					var floats:ByteArray = new ByteArray();
					buffer.readBytes(floats, 0, 4);
					floats.endian = Endian.LITTLE_ENDIAN;
					var float:Number = buffer.readFloat();
					return floats.readFloat();
				case 'double':
					var doubles:ByteArray = new ByteArray();
					buffer.readBytes(doubles, 0, 8);
					doubles.endian = Endian.LITTLE_ENDIAN;
					return doubles.readDouble();
				case 'string':
					var length:int = decodeUInt32(buffer);
					return buffer.readUTFBytes(length);
				default:
					var proto:Object = protos && (protos.__messages[type] || _servers["message " + type]);
					if(proto)
					{
						var len:int = decodeUInt32(buffer);
						
						if (len) 
						{
							var buf:ByteArray = new ByteArray();
							buffer.readBytes(buf, 0, len);
						}
						
						return len ? decodeProtos(proto, buf) : false;
					}
					break;
			}
		}
		
		private static function encodeArray(array:Array, proto:Object, protos:Object, buffer:ByteArray):void
		{
			if(isSimpleType(proto.type))
			{
				buffer.writeBytes(encodeTag(proto.type, proto.tag));
				buffer.writeBytes(encodeUInt32(array.length));
				for (var i:int = 0; i < array.length; i++) 
				{
					encodeProp(array[i], proto.type, protos, buffer);
				}
			}
			else
			{
				for (var j:int = 0; j < array.length; j++) 
				{
					buffer.writeBytes(encodeTag(proto.type, proto.tag));
					encodeProp(array[j], proto.type, protos, buffer);
				}
			}
			
			function isSimpleType(type:String):Boolean
			{
				return ( 
					type === 'uInt32' ||
					type === 'sInt32' ||
					type === 'int32'  ||
					type === 'uInt64' ||
					type === 'sInt64' ||
					type === 'float'  ||
					type === 'double'
				);
			};
		}
		
		private static function decodeArray(array:Array, type:String, protos:Object, buffer:ByteArray):void 
		{
			if(isSimpleType(type))
			{
				var length:int = decodeUInt32(buffer);
				for(var i:int = 0; i < length; i++)
				{
					array.push(decodeProp(type, protos, buffer));
				}
			}
			else
			{
				array.push(decodeProp(type, protos, buffer));
			}
			
			function isSimpleType(type:String):Boolean
			{
				return ( 
					type === 'uInt32' ||
					type === 'sInt32' ||
					type === 'int32'  ||
					type === 'uInt64' ||
					type === 'sInt64' ||
					type === 'float'  ||
					type === 'double'
				);
			};
		}
		
		private static function encodeUInt32(n:int):ByteArray
		{
			var result:ByteArray = new ByteArray();
			
			do
			{
				var tmp:int = n % 128;
				var next:int = Math.floor(n / 128);
				
				if(next !== 0){
					tmp = tmp + 128;
				}
				
				result.writeByte(tmp);
				n = next;
			}
			while(n !== 0);
			
			return result;
		}
		
		private static function decodeUInt32(buffer:ByteArray):int
		{
			var n:int = 0;
			
			for (var i:int = 0; i < buffer.length; i++)
			{
				var m:int = buffer.readUnsignedByte();
				n = n + ((m & 0x7f) * Math.pow(2,(7*i)));
				if (m < 128)
				{
					return n;
				}
			}
			return n;
		}
		
		private static function encodeSInt32(n:int):ByteArray
		{
			n = n < 0 ? (Math.abs(n) * 2 - 1) : n * 2;
			
			return encodeUInt32(n);
		}
		
		private static function decodeSInt32(buffer:ByteArray):int
		{
			var n:int = decodeUInt32(buffer);
			
			var flag:int = ((n % 2) === 1) ? -1 : 1;
			
			n = ((n % 2 + n) / 2) * flag;
			
			return n;
		}
	}
}
