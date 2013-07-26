package org.idream.pomelo
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import org.idream.pomelo.interfaces.IPackage;

	public class Package implements IPackage
	{
		public static const TYPE_HANDSHAKE:int = 1;
		public static const TYPE_HANDSHAKE_ACK:int = 2;
		public static const TYPE_HEARTBEAT:int = 3;
		public static const TYPE_DATA:int = 4;
		public static const TYPE_KICK:int = 5;
		
		public function encode(type:int, body:ByteArray = null):ByteArray
		{
			var length:int = body ? body.length : 0;
			
			var buffer:ByteArray = new ByteArray();
			buffer.writeByte(type & 0xff);
			buffer.writeByte((length >> 16) & 0xff);
			buffer.writeByte((length >> 8) & 0xff);
			buffer.writeByte(length & 0xff);
			
			if(body) buffer.writeBytes(body, 0, body.length);
			
			return buffer;
		}
		
		public function decode(buffer:IDataInput):Object
		{
			var type:int = buffer.readUnsignedByte();
			var len:int = (buffer.readUnsignedByte() << 16 | buffer.readUnsignedByte() << 8 | buffer.readUnsignedByte()) >>> 0;
			
			if (buffer.bytesAvailable >= len)
			{
				var body:ByteArray = new ByteArray();
				buffer.readBytes(body, 0, len);
			}
			else
			{
				trace("[Package] buffer length error:", type);
			}
			
			return {type:type, body:body, length:len};
		}
	}
}