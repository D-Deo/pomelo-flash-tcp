Pomelo-Flash-TCP
================

it`s a simple component for supporting pomelo-hybridconnector(tcp)

version: 0.0.5a

features:

1. support pomelo new protocol model (v0.4.x)


================


这是一个为了可以用 flash 的 as3 来和服务端的 pomelo 通讯的 tcp 组件，在自己的项目中已经可以和后台进行调试。

@已全面支持 pomelo 的 routeDict 和 服务端的 protobuf

相关的服务器可设置如下参数：
```javascript
app.set('connectorConfig', {
  connector : pomelo.connectors.hybridconnector,
  useDict : true,
  useProtobuf : true,
});
```
  
@目前 v0.0.5a 也已支持 Pomelo v0.4.x 中的新特性：自定义 Message 的编解码

客户端使用方法:

1. 创建一个实现了 IMessage 接口的类 (MyMessage)，并实现其接口方法：encode 和 decode，更多编解码内容可参考 Pomelo wiki

2. 在创建 Pomelo 的实例之后，可将自定义的 Message 实例赋值给 Pomelo 的 message 属性

相关客户端代码可参考如下形势：
```actionscript
var myMessage:IMessage = new MyMessage();
var pomelo:Pomelo = new Pomelo();
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
```


================


#1. 连接服务器
需要监听 pomelo 的 handshake 事件，连接成功后会触发此事件
```actionscript
var pomelo:Pomelo = new Pomelo()
pomelo.init("127.0.0.1", 3014);
pomelo.addEventListener("handshake", onSuccess);
```

@v0.0.2a 版本及以后，可以在 init 方法中直接传递一个 callback，无需监听 handshake 事件，不过此事件仍保留
```actionscript
pomelo.init("127.0.0.1", 3014, null, function(response:Object):void {
    if (response.code == 200) trace(response.user.msg);
});
```


#2. request && response
返回的response是一个object的对象，它解析自服务器的JSON对象
```actionscript
pomelo.request("connecter.LoginHandler.login", {}, function(response:Object):void {
    trace("response object : ", response);
});
```


#3. notify
notify是不需要服务器返回response的，所以没有callback
```actionscript
pomelo.notify("connector.roomHandler.enter", {});
```


#4. 服务器推送
利用 as3 的事件机制便可以完成接受服务器的推送内容，PomeloEvent有一个message的object参数，解析自服务器推送的JSON
```actionscript
pomelo.addEventListener("onStart", function(e:PomeloEvent):void {
  trace(e.message);
});
```
