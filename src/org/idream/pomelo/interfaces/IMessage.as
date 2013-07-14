package org.idream.pomelo.interfaces
{
	import flash.utils.ByteArray;

	public interface IMessage
	{
		/**
		 * encode
		 * @param reqId
		 * @param route
		 * @param msg
		 * @return ByteArray
		 */
		function encode(reqId:uint, route:String, msg:Object):ByteArray;
		
		/**
		 * decode
		 * @param buffer
		 * @return Object
		 */
		function decode(buffer:ByteArray):Object;
	}
}