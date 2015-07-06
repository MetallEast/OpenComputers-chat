# OpenComputers-chat


<h3>Server<br /></h3>
Server type: Parallel<br />
Consists of three levels.<br />
Each level is broadcasting only in its own separate port.<br/>

1. Registration Level.    Registration of new users is going on here.<br/>
2. Authentication Level.  Registered users login here.<br/>
3. Primary Level.         Actually the chat.<br/>

<i><b>Note</b>: User names and passwords stored in a "users" file.</i><br/>
<i><b>Note</b>: Primary level has a random port each new uptime cycle.</i>
<i><b>Recommended</b>: Register the "Server.lua" script in autorun.lua on the server side<br/>

**Configuration**<br/>
The server must be set at least wireless card.<br/>
Everything else is at your discretion.<br/>

<h3>Client<br/></h3>

The client computer must have at least one wireless card.<br/>
When the chat starts the first thing checked connection to the server<br/>
After logging the client receives primary level port from the server. (chat port)<br/>
"exit" command used to exit from chat.<br/>


<b>Remark</b>: thread.lua code is written by [Zer0Galaxy](http://computercraft.ru/topic/634-esche-odin-podkhod-k-mnogopotochnosti-v-opencomputers/)<br/>
Code: [thread.lua](http://pastebin.com/E0SzJcCx)<br/>
