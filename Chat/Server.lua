local thread = require("thread")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local text = require("text")

local modemPrim = component.proxy("79c5fa93-e6bd-4e97-80cc-193c4b6a1898")
local modemAuth = component.proxy("9ed56ccb-b4c4-4dba-bb2d-50dccb844942")
local modemReg  = component.proxy("9f54fd85-eec4-4d75-8830-0924570d54bc")
local primaryPort = math.random(512, 1024)


function RegistrationLevel()
	local _, _, address, port, _, message
	while true do
		while port ~= 255 do
			_, _, address, port, _, message = event.pull("modem_message")
		end
		port = nil
		local newUser = serialization.unserialize(message)
		if string.len(newUser[1]) > 15 or string.len(newUser[1]) < 3 then 
			modemReg.send(address, 255, "Длина имени пользователя должна быть от 3 до 15 символов")
		else
			local file = io.open("users", "a")
			io.output(file)
			local line
			file:seek("set")
			while true do
				line = file:read()
				file:read()
				if newUser[1] == line then
					modemReg.send(address, 255, "Пользователь с таким именем уже существует")
					break
				end		
				if line == nil then
					io.input(file)
					file:seek("end")
					file:write("\n")
					file:write(newUser[1])
					file:write("\n")
					file:write(newUser[2])
					modemReg.send(address, 255, 1)		
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
					 modemAuth.send(address, 256, primaryPort)	
				else modemAuth.send(address, 256, "Неверный пароль")						
				end
				break
			end		
			if line == nil then 					
				modemAuth.send(address, 256, "Пользователя с таким именем не существует")
				break
			end 			 
		end
		file:close(file)
	end
end

function PrimaryLevel()
	local check
	local _, _, address, port = nil, _, message
	while true do
		while port ~= primaryPort do
			_, _, address, port, _, message = event.pull("modem_message")
			print("Address:", address, "\nPort:\t", port, "\nMessage:", message)
		end
		port = nil
		check = text.trim(message)
		check = text.detab(check, 1)
		if check ~= "" and string.len(message) < 256 then
			modemPrim.broadcast(primaryPort, message)
		end
	end
end


modemReg.open(255)
modemAuth.open(256)
modemPrim.open(primaryPort)
modemReg.setStrength(5000)
modemAuth.setStrength(5000)
modemPrim.setStrength(5000)

thread.init()
thread.create(RegistrationLevel)
thread.create(AuthenticationLevel)
PrimaryLevel()

modemReg.close(255)
modemAuth.close(256)
modemPrim.close(primaryPort)
thread.killAll()
thread.waitForAll()