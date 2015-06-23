# OpenComputers-chat

By the way: [thread.lua](http://computercraft.ru/topic/393-esche-odin-podkhod-k-mnogopotochnosti-v-computercraft/) code is written by Zer0Galaxy

<h3>Server<br /></h3>
Consists of three levels.<br />
Each level is broadcasting only in its own separate port.<br />
A separate thread for each level.<br />

1. Registration Level.    Registration of new users is going on here.<br />
2. Authentication Level.  Registered users login here.<br />
3. Primary Level.         Actually the chat.<br />

<i><b>Note</b>: Primary level has a random port each new uptime cycle.</i>

**Configuration**<br />
The server must be set three wireless card. One card for each level.<br />
Everything else is at your discretion.<br />

<i><b>Note</b>: string.len(s) returns the length of a string s in bytes.<br />
russian letter - 2 bytes, english letter and ASCII symbols - 1 byte.</i>

<h3>Client<br /></h3>

The client computer must have at least one wireless card.<br />
After logging the client receives primary level port from the server. (chat port)
