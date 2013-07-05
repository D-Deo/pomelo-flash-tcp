package org.idream.pomelo
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class Protobuf
	{
		public static function encode():void
		{
			
		}
		
		public static function decode(protos:Object, buffer:ByteArray):Object
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
		
		public static function getHead(buffer:ByteArray):Object
		{
			var tag:int = decodeUInt32(buffer);
			
			return { type: tag & 0x7, tag: tag >> 3 };
		}
		
		public static function decodeProp(type:String, protos:Object, buffer:ByteArray):*
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
					if(!!protos && !!protos.__messages[type])
					{
						var len:int = decodeUInt32(buffer);
						var buf:ByteArray = new ByteArray();
						buffer.readBytes(buf, 0, len);
						return decode(protos.__messages[type], buf);
					}
					break;
			}
		}
		
		public static function decodeArray(array:Array, type:String, protos:Object, buffer:ByteArray):void 
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
		
		public static function decodeUInt32(buffer:ByteArray):int
		{
			var n:int = 0;
			
			for (var i:int = 0; i < buffer.length; i++)
			{
//				trace("i: ", i);
				var m:int = buffer.readUnsignedByte();
//				trace("m: " + m);
				n = n + ((m & 0x7f) * Math.pow(2,(7*i)));
				if (m < 128)
				{
//					trace("n: " + n);
					return n;
				}
			}
//			trace("n: " + n);
			return n;
		}
		
		public static function decodeSInt32(buffer:ByteArray):int
		{
			var n:int = decodeUInt32(buffer);
			
			var flag:int = ((n % 2) === 1) ? -1 : 1;
			
			n = ((n % 2 + n) / 2) * flag;
			
//			trace("n: " + n);
			return n;
		}
	}
}