-- thread.lua code is written by Zer0Galaxy
-- Code:  http://pastebin.com/E0SzJcCx

local thread = require("thread")
local computer = require("computer")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local text = require("text")
local term = require("term")
local unicode = require("unicode")
local modem = component.modem
local gpu = component.gpu

local serverAddress
local primaryPort
local myMessage
local A, B
local name
local online = 1
local sHandler, rHandler

function Registration()
	local _, _, address, _, _, message
	local user = {}
	term.clear()
	term.write("Имя пользователя: ")
	local nickname = text.trim(term.read())
	term.write("Пароль: ")
	local password = text.trim(term.read(nil, true, nil, "*"))
	term.write("Повторите пароль: ")
	local repetition = text.trim(term.read(nil, true, nil, "*"))
	if password ~= repetition then 
		term.write("\nЗначения полей 'Пароль' и 'Повтор пароля' должны совпадать")
		os.sleep(0.5)
	else 
		user[1] = nickname
		user[2] = password
		local packet = serialization.serialize(user)
		modem.open(255)
		modem.send(serverAddress, 255, packet)
		while address ~= serverAddress do
			_, _, address, _, _, message = event.pull("modem_message")
		end
		modem.close(255)
		if type(message) == "number" then
			term.clear()
			print("Регистрация завершена")
		else print(message) end
	end
	event.pull("key_up")
	term.clear()
end

function Authentication()
	term.write("Имя пользователя: ")
	local nickname = text.trim(term.read())
	term.write("Пароль: ")
	local password = text.trim(term.read(nil, true, nil, "*"))
	local user = {}
	user[1] = nickname
	user[2] = password
	local packet = serialization.serialize(user)
	modem.open(256)
	modem.send(serverAddress, 256, packet)
	local _, _, address, _, _, message
	while address ~= serverAddress do
		_, _, address, _, _, message = event.pull("modem_message")
	end
	modem.close(256)
	if type(message) == "number" then 
		name = nickname
		return message 
	else 
		print(message)
		os.sleep(0.5)
		event.pull("key_up")
		term.clear()
		return 0
	end
end

function Choice()
	local _,_,_,choice
	local authResult
	while true do
		print("1. Войти в чат")
		print("2. Регистрация")
		print("3. Выход\n")
		_, _, _, choice = event.pull("key_up") 
		term.clear()
		if choice == 2 then 
			authResult = Authentication() 
			if authResult ~= 0 then
				return authResult		
			end
		end
		if choice == 3 then Registration() end
		if choice == 4 then break end
	end
	return 0
end

function Receiver()
	local x, y		
	local _, _, address, port, _, message, mesHeight
	local chatWidth = math.floor(A * 0.75)
	local onlineLeftBorder = math.floor(A * 0.8)
	local online = {}
	while true do
		_, _, address, port, _, message = event.pull("modem_message")
		if address == serverAddress then
			address = nil
			if port == 253 then
				if message == 'P' then modem.send(serverAddress, 253, name)	-- 1
				else online = serialization.unserialize(message) end
			else
				x, y = term.getCursor()
				if message == 'R' or message == 'C' then
					term.setCursor(1, B - 5)
					if message == 'R' then print("[Server] Restarting...")
					else print("[Server] Shutting down...") end
					thread.kill(sHandler)
					term.setCursorBlink(false)
					os.sleep(3) 
					term.clear()
					break
				else
					mesHeight = math.floor(unicode.len(message) / chatWidth) + 1
					for i=1, mesHeight, 1 do
						term.setCursor(A, B)
						term.write(' ', true)
					end
					term.setCursor(1, B - 3 - mesHeight)
					message = text.trim(message)
					while true do
						if unicode.len(message) < chatWidth then print(message) break end
						print(unicode.sub(message, 1, chatWidth))
						message = unicode.sub(message, chatWidth)
					end
					gpu.copy(1, B - 2, A, 3, 0, mesHeight)
					
					term.setCursor(onlineLeftBorder, 1) term.write("--------------")
					term.setCursor(onlineLeftBorder, 2) term.write("--- ONLINE ---")
					term.setCursor(onlineLeftBorder, 3) term.write("--------------")
					for i=1,#online,1 do
						term.setCursor(onlineLeftBorder, i+3) 
						term.write("             ")
						term.setCursor(onlineLeftBorder, i+3) 
						term.write(online[i])
					end
					term.setCursor(x, B - 1)
					if message ~= myMessage then computer.beep(1000, 0.1) end
				end
			end
		end
	end
end

function Sender()
	local result
	local history = {}
	while true do 
		myMessage = term.read(history, false)
		result = text.trim(myMessage)
		result = text.detab(result, 1)
		if result == "exit" then 
			term.clear()
			thread.kill(rHandler)
			break
		end
		if unicode.len(result) > 1 then 
			myMessage = name .. ": " .. myMessage
			modem.send(serverAddress, primaryPort, myMessage)
		end
		term.clearLine()
		if #history > 5 then table.remove(history, 1) end
	end
end

function CheckConnection()
	local serverOn = false
	term.clear()
	term.write("Соединение...")
	modem.open(254)
	for try = 1, 3 do
		modem.broadcast(254, 1)
		local _, _, address, _, _, _ = event.pull(3, "modem_message")
		if address ~= nil then
			serverAddress = address
			serverOn = true
			break
		end
	end
	modem.close(254)
	term.clear()
	if serverOn == true then return 1 end
	return 0
end


modem.setStrength(5000)
if CheckConnection() == 1 then
	local choice = Choice()	
	if choice > 0 then 
		primaryPort = choice
		modem.open(primaryPort)
		modem.open(253)
		A, B = gpu.getResolution()
		term.clear()
		term.setCursor(1, B - 1)
		thread.init()
		rHandler = thread.create(Receiver)
		sHandler = thread.create(Sender)
		thread.waitForAll()
		modem.close()
	elseif choice == -1 then 
		print("Вы забанены на сервере") end
else
	print("Сервер недоступен")
	event.pull("key_up")
	term.clear()
end