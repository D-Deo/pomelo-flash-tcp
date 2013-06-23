package org.idream.pomelo
{
	import flash.events.Event;
	
	public class PomeloEvent extends Event
	{
		public var message:Object;
		
		public function PomeloEvent(type:String, message:Object = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.message = message;
		}
		
		override public function clone():Event
		{
			return new PomeloEvent(type, message, bubbles, cancelable);
		}
	}
}