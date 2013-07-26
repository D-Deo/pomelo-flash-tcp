package org.idream.pomelo
{
	
	public class Routedic
	{
		private static var _ids:Object = {};
		private static var _names:Object = {};
		
		public static function init(dict:Object):void
		{
			_names = dict || {};
			
			for (var name:String in _names)
			{
				_ids[_names[name]] = name;
			}
		}
		
		public static function getID(name:String):int
		{
			return _names[name];
		}
		
		public static function getName(id:int):String
		{
			return _ids[id];
		}
	}
}