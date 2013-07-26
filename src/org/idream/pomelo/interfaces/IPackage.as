package org.idream.pomelo.interfaces
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;

	public interface IPackage
	{
		function encode(type:int, body:ByteArray = null):ByteArray
		
		function decode(buffer:IDataInput):Object
	}
}