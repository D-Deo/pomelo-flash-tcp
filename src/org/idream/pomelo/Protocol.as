package org.idream.pomelo
{
	import flash.utils.ByteArray;

	public class Protocol
	{
		public static function strencode(str:String):ByteArray
		{
			var buffer:ByteArray = new ByteArray();
			buffer.length = str.length;
			buffer.writeUTFBytes(str);
			return buffer;
		}
		
		public static function strdecode(byte:ByteArray):String
		{
			return byte.readUTFBytes(byte.bytesAvailable);
		}
	}
}