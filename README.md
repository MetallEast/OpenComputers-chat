# OpenComputers-chat

The server and client must contain at least a wireless network card or network card. That's all.
<br/>Both client and server can be represented as you want — computer, server or even robot.

<h3>Server<br /></h3>
Server type: Parallel<br />
Consists of three levels.<br />
Each level is broadcasting only in its own separate port.<br/>
<li/> 1. Registration Level.    Registration of new users is going on here.<br/>
<li/> 2. Authentication Level.  Registered users login here.<br/>
<li/> 3. Primary Level.         Actually the chat.<br/>

<i><b>Note</b>: User names and passwords stored in a "users" file.</i><br/>
<i><b>Note</b>: Primary level has a random port each new uptime cycle.</i><br/>
<i><b>Recommended</b>: Register the "Server.lua" script in autorun.lua on the server side</i><br/>

<ins>Server commands</ins><br/>
<i>restart</i> - forced restart.<br/>
<i>close</i> - сlose server immediately.<br/>
<i>[message]</i> - broadcast message with tag [Server].<br/>
<i>ban [nickname]</i> - ban by nickname (row in banlist).<br/>

Configuration example:
```lua
home> edit server
* Paster Server.lua code here
* Ctrl-S
* Ctrl-W
home> server
```
If you saw _"Log file size — 0 bytes"_ then server configure is done.

<h3>Client<br/></h3>

When the chat starts the first thing checked connection to the server<br/>
After logging the client receives primary level port from the server. (chat port)<br/>
"exit" command used to exit from chat.<br/>

Configuration example:
```lua
home> edit client
* Paster Client.lua code here
* Ctrl-S
* Ctrl-W
home> client
```
<hr/>
<h3>Known issue</h3>
Do not work as expected since OC 1.6
