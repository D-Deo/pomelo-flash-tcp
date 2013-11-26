Pomelo-Flash-TCP
================

version: 0.1.5b

features:

1. add [Event] metadata for how to know events

2. add kicked event when server disconnect client

================

version: 0.1.4b

features:

1. merge some changes from @iggyZiggy, it`s about developers can use weak or not.

================

version: 0.1.3b

features:

1. add beat function, now if call this, client will send heartbeat to server

================

version: 0.1.2b

features:

1. implement heartbeat from server, now client will echo server

2. add timeout checking as connecting

bugs:

1. fix decoding when length of pkg is 0, the body just create a empty ByteArray

2. fix and improve instance of socket by using

================

version: 0.1.1b

features:

1. add Security to check 3843 of port

2. add support for root message of protobuf

================

version: 0.1.0b

features:

1. refactor project for improving

2. change decoding for fixing a bug which sometimes can`t be read linked package 

3. add a getIns() static function for single model

================

version: 0.0.5a

features:

1. support pomelo new protocol model (v0.4.x)

================

version: 0.0.4a

features:

1. support client port of protobuf (client encode and server decode)

================

version: 0.0.3a

features:

1. support routeDict

2. support server port of protobuf (server encode and client decode)

================

version: 0.0.2a

features:

1. add a test about how to support gate server (as lordofpomelo)

2. clean code

================