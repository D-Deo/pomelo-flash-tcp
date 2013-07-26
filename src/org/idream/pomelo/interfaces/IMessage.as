package org.idream.pomelo.interfaces
{
	import flash.utils.ByteArray;

	public interface IMessage
	{
		/**
		 * encode
		 * @param id
		 * @param route
		 * @param msg
		 * @return ByteArray
		 */
		function encode(id:uint, route:String, msg:Object):ByteArray;
		
		/**
		 * decode
		 * @param buffer
		 * @return Object
		 */
		function decode(buffer:ByteArray):Object;
	}
}