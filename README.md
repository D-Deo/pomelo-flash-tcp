Pomelo-Flash-TCP
================

it`s a simple component for supporting pomelo-hybridconnector(tcp)

version: 0.0.4a

features:

1. support client port of protobuf (client encode and server decode)


================


这是一个为了可以用 flash 的 as3 来和服务端的 pomelo 通讯的 tcp 组件，在自己的项目中已经可以和后台进行调试。

@目前 v0.0.4a 已全面支持 pomelo 的 routeDict 和 服务端的 protobuf

相关的服务器可设置如下参数：
```javascript
app.set('connectorConfig', {
  connector : pomelo.connectors.hybridconnector,
  useDict : true,
  useProtobuf : true,
});
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
