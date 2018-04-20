-- thread.lua code is written by Zer0Galaxy
-- Code: http://pastebin.com/E0SzJcCx

local thread = require("thread")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local text = require("text")
local term = require("term")
local unicode = require("unicode")
local modem = component.modem
local primaryPort = math.random(512, 1024)
local restart = false

function InitialiseFiles()
	local fs = require("filesystem")
	local shell = require("shell")
	shell.setWorkingDirectory("/chat/")
	local curDir = shell.getWorkingDirectory()
	local users = io.open(curDir .. "users", "ab")     users:close(users)
	local banlist = io.open(curDir .. "banlist", "ab") banlist:close(banlist)
	if fs.size(curDir .. "log") > 500000 then
		fs.rename(curDir .. "log", curDir .. "log_old")
		print("New log file created. Old log file saved as log_old")
	else print("Log file size — " .. fs.size(curDir .. "log") .. " bytes") end
end

function Log(address, port, message)
	local log = io.open("log", "ab")
	io.input(log)
	log:seek("end")	
	log:write(address .. ':' .. port .. '\n' .. message .. '\n')
	log:close(log)
end

function CheckBanList(nickname)
	local line
	local file = io.open("banlist", "rb")
	io.output(file)
	file:seek("set")
	while true do
		line = file:read()
		if nickname == line then return 0 end	
		if line == nil then return 1 end 		
	end
	file:close(file)	
end

function AddToBanList(nickname)
	if CheckBanList(nickname) == 1 then
		local file = io.open("banlist", "ab")
		io.input(file)
		file:seek("end")
		file:write(string.format("%s\n", nickname))
		file:close(file)
		modem.broadcast(primaryPort, nickname .. " was banned")
	end
end

function ModemSettings()
	modem.open(253)
	modem.open(254)
	modem.open(255) 
	modem.open(256)
	modem.open(primaryPort)
	modem.setStrength(5000)
end

local count, isFlooder, flooder = 1, false, nil
function FloodReset()
	count, isFlooder, flooder = 1, false, nil
end

function Manager()
	local _, _, address, port, _, message
	local lastaddress, nickname, mute
	while true do
		_, _, address, port, _, message = event.pull("modem_message")
		if 	port == primaryPort then 
			if isFlooder == true and flooder == address then goto continue
			else PrimaryLevel(message) end
		elseif	port == 256 then AuthenticationLevel(address, message)
		elseif	port == 255 then RegistrationLevel(address, message)
		elseif	port == 254 then modem.send(address, 254, 1) end
		Log(address, port, message)	
		-- Anti-flood
		if lastaddress == address and port == primaryPort then
			count = count + 1 
			if count > 3 then 
				event.timer(10, FloodReset)
				isFlooder, flooder = true, lastaddress
				nickname = string.sub(message, 1, string.find(message, ":") - 1)
				mute = "[Server] " .. nickname .. " muted for 10 seconds"
				modem.broadcast(primaryPort, mute)
			end
		else 
			lastaddress = address
			count = 0
		end
		::continue::
	end
end

function PingUsers()
	while true do
		local online = {}
		local _, _, address, port, _, username, packet
		event.pull(30, "waiting")
		modem.broadcast(253, 'P')
		while true do
			_, _, address, port, _, username = event.pull(3, "modem_message")
			if port == nil then break end
			if port == 253 then table.insert(online, username) end
		end
		table.sort(online)
		packet = serialization.serialize(online)
		modem.broadcast(253, packet)
	end
end	

function RegistrationLevel(address, message)
	local user = serialization.unserialize(message)
	if 	unicode.len(user[1]) < 3 or unicode.len(user[1]) > 15  or
		unicode.len(user[2]) < 3 or unicode.len(user[2]) > 10  then
		modem.send(address, 255, "Name length must be 3 to 15 characters\nPassword length must be 3 to 15 characters")
	else if string.find(user[1], "[%p%c%d]") ~= nil then
		modem.send(address, 255, "Name contains incorrect characters")
		else
			local line
			local file = io.open("users", "rb")
			io.output(file)
			while true do
				line = file:read()
				if user[1] == line then
					modem.send(address, 255, "User already exist")
					break end		
				file:read()
				line = file:read()
				if line == address then 
					modem.send(address, 255, "User already registered from this address")
					break end
				if line == nil then
					file:close(file)
					file = io.open("users", "ab")
					io.input(file)
					local c = file:seek("end")
					if c ~= 0 then file:write(string.format("\n%s\n%s\n%s", user[1], user[2], address))
					else file:write(string.format("%s\n%s\n%s", user[1], user[2], address)) end
					modem.send(address, 255, 1)				
					break
				end 	
			end
			file:close(file)
		end
	end
end

function AuthenticationLevel(address, message)
	local user = serialization.unserialize(message)
	local line
	local file = io.open("users", "rb")
	io.output(file)
	file:seek("set")
	while true do
		line = file:read()
		if user[1] == line then
			if CheckBanList(user[1]) == 0 then 
				modem.send(address, 256, -1) break end
			line = file:read()
			if user[2] == line then 				
				modem.send(address, 256, primaryPort)	
				modem.broadcast(primaryPort, user[1] .. " joined to chat")
			else modem.send(address, 256, "Incorrect password") end
			break
		else file:read() file:read() end
		if line == nil then 	
			modem.send(address, 256, "Username does not exist")
			break
		end 		
	end
	file:close(file)
end

function PrimaryLevel(message)
	local check, nicklen, mlen
	check = text.trim(message)
	nicklen = string.find(check, ':')
	mlen = unicode.len(message) - nicklen - 2
	if mlen > 0 and mlen < 256 
		then modem.broadcast(primaryPort, message) end
end
	
function Administration()
	local command 
	while true do
		command = term.read()
		command = text.trim(command)
		if command == "restart" then restart = true
			modem.broadcast(primaryPort, 'R') break end
		if command == "close" then 
			modem.broadcast(primaryPort, 'C') break end
		if unicode.sub(command, 1, 4) == "ban " then AddToBanList(unicode.sub(command, 5))
		else modem.broadcast(primaryPort, string.format("[Server] %s", command)) end 
	end
end

InitialiseFiles()
thread.init()			
ModemSettings()
thread.create(PingUsers)
thread.create(Manager)
Administration()
thread.killAll()
thread.waitForAll()
modem.close()
if restart == true then os.execute("reboot") end
