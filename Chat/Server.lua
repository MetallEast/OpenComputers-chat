local thread = require("thread")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local text = require("text")
local unicode = require("unicode")

local modem = component.proxy("596f1d35-8939-4406-9f1d-a22cf9d31c76")
local primaryPort = math.random(512, 1024)

-- Ping Level				Port: 254
-- Registration Level		Port: 255
-- Authentication Level		Port: 256
-- Primary Level			Port: Random

function PingLevel()
	local _, _, address, port, _, message
	while true do
		while port ~= 254 do
			_, _, address, port, _, message = event.pull("modem_message")
		end
		modem.send(address, 254, 1)
	end
end

function RegistrationLevel()
	local _, _, address, port, _, message, file, line
	while true do
		while port ~= 255 do
			_, _, address, port, _, message = event.pull("modem_message")
		end
		port = nil
		local user = serialization.unserialize(message)
		if 	unicode.len(user[1]) < 3 or unicode.len(user[1]) > 15  or
			unicode.len(user[2]) < 3 or unicode.len(user[2]) > 10  then
				modem.send(address, 255, "Имя должно быть от 3 до 15 символов\nПароль должен быть от 3 до 10 символов")
		else
			file = io.open("users", "a")
			io.output(file)
			while true do
				line = file:read()
				file:read()
				if user[1] == line then
					modem.send(address, 255, "Пользователь с таким именем уже существует")
					break
				end		
				if line == nil then
					io.input(file)
					file:seek("end")
					local newUser = string.format("%s\n%s\n", user[1], user[2])
					file:write(newUser)
					modem.send(address, 255, 1)		
					break
				end 	
			end
			file:close(file)
		end
	end
end

function AuthenticationLevel()
	local _, _, address, port, _, message
	local line
	while true do
		while port ~= 256 do
			_, _, address, port, _, message = event.pull("modem_message")
		end
		port = nil
		local user = serialization.unserialize(message)
		local file = io.open("users", "r")
		io.output(file)
		file:seek("set")
		while true do
			line = file:read()
			if user[1] == line then
				line = file:read()
				if user[2] == line then 				
					modem.send(address, 256, primaryPort)	
				else 
					modem.send(address, 256, "Неверный пароль") 					
				end
				break
			end		
			if line == nil then 	
				modem.send(address, 256, "Пользователя с таким именем не существует")
				break
			end 		
		end
		file:close(file)
	end
end

function PrimaryLevel()
	local check
	local _, _, address, port, _, message
	while true do
		while port ~= primaryPort do
			_, _, address, port, _, message = event.pull("modem_message")
			print("Address:", address, "\nPort:\t", port, "\nMessage:", message)
		end
		port = nil
		check = text.trim(message)
		if check ~= "" and unicode.len(message) < 128 then
			modem.broadcast(primaryPort, message)
		end
	end
end


modem.open(254)
modem.open(255)
modem.open(256)
modem.open(primaryPort)
modem.setStrength(5000)

thread.init()
thread.create(PingLevel)
thread.create(RegistrationLevel)
thread.create(AuthenticationLevel)
PrimaryLevel()

modem.close()
thread.killAll()
thread.waitForAll()