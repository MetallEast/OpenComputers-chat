-- thread.lua code is written by Zer0Galaxy
-- Topic: http://computercraft.ru/topic/634-esche-odin-podkhod-k-mnogopotochnosti-v-opencomputers/
-- Code:  http://pastebin.com/E0SzJcCx

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

function Log(address, port, message)
	local log = io.open("log", "ab")
	io.input(log)
	log:seek("end")	
	log:write('\n' .. address .. ':' .. port .. '\n' .. message)
	log:close(log)
end

function ModemSettings()
	modem.open(253)
	modem.open(254)
	modem.open(255) 
	modem.open(256)
	modem.open(primaryPort)
	modem.setStrength(5000)
end

function Manager()
	local users = io.open("users", "ab")
	users:close(users)
	local _, _, address, port, _, message
	while true do
		_, _, address, port, _, message = event.pull("modem_message")
		if 		port == primaryPort then PrimaryLevel(message)
		elseif	port == 256 then AuthenticationLevel(address, message)
		elseif	port == 255 then RegistrationLevel(address, message)
		elseif	port == 254 then modem.send(address, 254, 1) end
		Log(address, port, message)
	end
end

function PingUsers()
	while true do
		local online = 0
		local _, _, address, port, _, _
		event.pull(17, "waiting")
		modem.broadcast(253, 'P')
		while true do
			_, _, address, port, _, _ = event.pull(3, "modem_message")
			if port == nil then break end
			if port == 253 then online = online + 1 end
		end
		if online == 0 then online = 1 end
		modem.broadcast(253, online)
	end
end	

function RegistrationLevel(address, message)
	local user = serialization.unserialize(message)
	if 	unicode.len(user[1]) < 3 or unicode.len(user[1]) > 15  or
		unicode.len(user[2]) < 3 or unicode.len(user[2]) > 10  then
		modem.send(address, 255, "Имя должно быть от 3 до 15 символов\nПароль должен быть от 3 до 10 символов")
	else if string.find(user[1], "[%p%c%d]") ~= nil then
		modem.send(address, 255, "Имя содержит запрещенные символы")
		else
			local line
			local file = io.open("users", "rb")
			io.output(file)
			while true do
				line = file:read()
				if user[1] == line then
					modem.send(address, 255, "Пользователь с таким именем уже существует")
					break end		
				file:read()
				line = file:read()
				if line == address then 
					modem.send(address, 255, "С Вашего адреса уже зарегестрирован пользователь")
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
	local line
	local user = serialization.unserialize(message)
	local file = io.open("users", "rb")
	io.output(file)
	file:seek("set")
	while true do
		line = file:read()
		if user[1] == line then
			line = file:read()
			if user[2] == line then 				
				modem.send(address, 256, primaryPort)	
				modem.broadcast(primaryPort, user[1] .. " присоединился к чату")
			else modem.send(address, 256, "Неверный пароль") end
			break
		else file:read() file:read() end
		if line == nil then 	
			modem.send(address, 256, "Пользователя с таким именем не существует")
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
	if mlen > 1 then modem.broadcast(primaryPort, message) end
end
	
function Administration()
	local command 
	while true do
		command = term.read()
		command = text.trim(command)
		if command == "restart" then restart = true
			modem.broadcast(primaryPort, 'R') break end
		if command == "close" then 
			modem.broadcast(primaryPort, 'C') break
		else modem.broadcast(primaryPort, string.format("[Server] %s", command)) end 
	end
end
	
thread.init()			
ModemSettings()
thread.create(PingUsers)
thread.create(Manager)
Administration()
thread.killAll()
thread.waitForAll()
modem.close()
if restart == true then os.execute("reboot") end