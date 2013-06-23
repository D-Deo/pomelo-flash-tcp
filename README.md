pomelo-flash-tcp
================

it`s a simple component for supporting pomelo-hybridconnector(tcp)

这是一个为了可以用 flash 的 as3 来和服务端的 pomelo 通讯的 tcp 组件，因为出于一些其他原因，所以并没有做到最好，但是在自己的项目中已经可以和后台进行调试。

目前该组件不支持 pomelo 的 protobuf 和 dict，后台调试时需设置：
```actionscript
app.set('connectorConfig', {
  connector : pomelo.connectors.hybridconnector,
  useDict : false,
  useProtobuf : false,
});
```
  

================


＃1. 连接服务器
需要监听 pomelo 的 handshake 事件，连接成功后会触发此事件
```actionscript
var pomelo:Pomelo = new Pomelo()
pomelo:init({ 'host': "127.0.0.1", 'port': 3010 });
pomelo.addEventListener("handshake", onSuccess);
```

＃2. request && response
返回的response是一个object的对象，它解析自服务器的JSON对象
```actionscript
pomelo.request("connecter.LoginHandler.login", {}, function(response:Object):void {
  trace("response object : ", response);
});
```

＃3. notify
notify是不需要服务器返回response的，所以没有callback
```action script
pomelo.notify("connector.roomHandler.enter", {});
```

＃4. 服务器推送
利用 as3 的事件机制便可以完成接受服务器的推送内容，PomeloEvent有一个message的object参数，解析自服务器推送的JSON
```actionscript
pomelo.addEventListener("onStart", function(e:PomeloEvent):void {
  trace(e.message);
});
```
