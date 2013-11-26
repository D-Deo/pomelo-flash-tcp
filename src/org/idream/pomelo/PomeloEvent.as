package org.idream.pomelo
{
	import flash.events.Event;
	
	public class PomeloEvent extends Event
	{
		/**
		 * 连接 Pomelo 服务器成功并验证成功
		 */
		public static const HANDSHAKE:String = "handshake";
		
		/**
		 * 被 Pomelo 服务器踢出
		 */
		public static const KICKED:String = "kicked";
		
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