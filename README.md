Pomelo-Flash-TCP
================

这是一个用来支持 pomelo-hybridconnector(tcp) 的 flash 通讯组件，底层使用的是 flash socket 的二进制协议

案例参考：https://github.com/mani95lisa/PomeloFlashDemo

目前版本：0.1.6b

主要更新：

1. 开放自定义安全策略文件的端口，init方法可以设置，默认3843

2. 修改 message 部分的 id encode/decode 方法


补充说明：

v0.1.6 beta 现已正式支持 pomelo 7.x， 估计是 0.2.0 正式版更新前的最后一个 beta 了，但是目前不支持 pomelo 6.x 的 RSA 加解密，因为 as3 目前的 RSA 加解密组件和官方的暂时不兼容，此问题日后有机会再解决，如果有其他高人可以帮忙解决，再次先感谢一下了

================

@已全面支持 pomelo 的 routeDict， 服务端的 protobuf， 以及心跳判断 heartbeat

相关的服务器可设置如下参数：
```javascript
app.set('connectorConfig', {
  connector : pomelo.connectors.hybridconnector,
  heartbeat : 30,
  disconnectOnTimeout : true    //现在你可以设置这个参数了
  useDict : true,
  useProtobuf : true
});
```
  
@已支持 Pomelo v0.4.x 中的新特性：自定义 Message 的编解码

客户端使用方法:

1. 创建一个实现了 IMessage 接口的类 (MyMessage)，并实现其接口方法：encode 和 decode，更多编解码内容可参考 Pomelo wiki 上的消息协议

2. 在创建 Pomelo 的实例之后，可将自定义的 Message 实例赋值给 Pomelo 的 message 属性

相关客户端代码可参考如下形势：
```actionscript
var myMessage:IMessage = new MyMessage();
var pomelo:Pomelo = Pomelo.getIns();
pomelo.message = myMessage;
```


相关的服务器可在 app.js 中添加如下方法：
```javascript
var encode = function(reqId, route, msg) {
  // do some customized encode with reqId, route and msg
  return result;	// return encode result
};

var decode = function(msg) {
  // do some customized decode with msg
  return result;	// return decode result
};

app.set('connectorConfig', {
  connector : pomelo.connectors.hybridconnector,
  encode: encode,
  decode: decode
});
```


How To Use
================

##1. 初始化并连接服务器

###新版本推荐使用单例模式来初始化 pomelo 对象，连接成功会返回一个 handshake 事件
```actionscript
/**
 * 初始化客户端，并尝试连接服务器
 * @param host
 * @param port
 * @param user 客户端与服务器之间的自定义数据
 * @param callback 当连接成功会调用此方法
 */
public function init(host:String, port:int, user:Object = null, callback:Function = null):void {}
```

###for example:
```actionscript
var pomelo:Pomelo = Pomelo.getIns();
pomelo.init("127.0.0.1", 3014);
pomelo.addEventListener("handshake", function(event:Event):void {
    trace("connect success ...");
});
```

###也可以在 init 方法中直接传递一个 callback, 以便于处理一些连接异常，目前推荐用此方式
```actionscript
pomelo.init("127.0.0.1", 3014, null, function(response:Object):void {
    if (response.code == 200) trace("connect success ...");
    else trace("connect failed:", response.code);
});
```


##2. 请求服务器数据

###response 是一个 object 的对象，它解析自服务器的返回的数据
```actionscript
/**
 * 向服务器请求数据
 * @param route
 * @param msg
 * @param callback 服务器返回数据时会回调
 */
public function request(route:String, msg:Object, callback:Function = null):void {}
```

###for example:
```actionscript
pomelo.request("gate.gateHandler.entry", {}, function(response:Object):void {
    trace("response host:", response.host, " port:", response.port);
});
```


##3. 向服务器发送数据，无返回

###notify 是不需要服务器返回 response 的，所以没有callback，或者 request 方法里不携带 callback 参数亦可
```actionscript
/**
 * 向服务器发送数据
 * @param route
 * @param msg
 */
public function notify(route:String, msg:Object):void {}
```

###for example:
```actionscript
pomelo.notify("connector.connectHandler.leave", {});
```


##4. 服务器推送

###利用 as3 的事件机制或 on 方法监听服务器的推送，PomeloEvent 的 message 解析自服务器推送的数据
```actionscript
/**
 * 响应服务器的推送事件
 * @param route 推送事件的名称
 * @param callback 当服务器发生推送时会调用此函数
 */
public function on(route:String, callback:Function):void {}
```

###for example:
```actionscript
pomelo.on("onServerPush", function(e:PomeloEvent):void {
  trace(e.message);
});
```

##5. 断开服务器

###客户端可主动与服务器断开连接，断开后，需重新调用 init 方法才可重连
```actionscript
/**
 * 与服务器主动断开连接
 */
public function disconnect():void {}
```
