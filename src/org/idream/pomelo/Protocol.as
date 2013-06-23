package org.idream.pomelo
{
	import flash.utils.ByteArray;

	public class Protocol
	{
		public static function strencode(str:String):ByteArray
		{
//			var byteArray:ByteArray = new ByteArray();
//			byteArray.length = str.length * 3;
//			var offset:int = 0;
//			for(var i:int = 0; i < str.length; i++){
//				var charCode:Number = str.charCodeAt(i);
//				var codes:* = null;
//				if(charCode <= 0x7f){
//					codes = [charCode];
//				}else if(charCode <= 0x7ff){
//					codes = [0xc0|(charCode>>6), 0x80|(charCode & 0x3f)];
//				}else{
//					codes = [0xe0|(charCode>>12), 0x80|((charCode & 0xfc0)>>6), 0x80|(charCode & 0x3f)];
//				}
//				for(var j:int = 0; j < codes.length; j++){
//					byteArray[offset] = codes[j];
//					++offset;
//				}
//			}
//			var buffer:ByteArray = new ByteArray();
//			buffer.length = offset;
//			buffer.writeBytes(byteArray, 0, offset);
			
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