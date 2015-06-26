local thread = require("thread")
local computer = require("computer")
local component = require("component")
local term = require("term")
local text = require("text")
local serialization = require("serialization")
local event = require("event")
local unicode = require("unicode")
local modem = component.modem
local gpu = component.gpu

local serverAddress = "596f1d35-8939-4406-9f1d-a22cf9d31c76"
local primaryPort
local myMessage
local A, B
local name

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
		return message -- 1&
	else 
		print(message)
		os.sleep(0.5)
		event.pull("key_up")
		term.clear()
		return 0
	end
end

function Registration()
	local _, _, _, _, _, message
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
		_, _, _, _, _, message = event.pull("modem_message")
		modem.close(255)
		if type(message) == "number" then
			term.clear()
			print("Регистрация завершена")
		else 
			print(message) 
		end
	end
	event.pull("key_up")
	term.clear()
end

function Choice()
	local choice
	local authResult
	while true do
		print("1. Войти в чат")
		print("2. Регистрация")
		print("3. Выход\n")
		choice = text.trim(term.read(nil, false))
		term.clear()
		if choice == "1" then 
			authResult = Authentication() 
			if authResult ~= 0 then
				return authResult		
			end
		end
		if choice == "2" then Registration() end
		if choice == "3" then break end
	end
	return 0
end

function Receiver()
	local x, y		
	local _, _, address, _, _, message
	while true do
		while address ~= serverAddress do
			_, _, address, _, _, message = event.pull("modem_message")
		end
		address = nil
		x, y = term.getCursor()
		term.setCursor(1, B - 5)
		print(text.trim(message))
		term.setCursor(A, B)
		term.write(' ', true)
		gpu.copy(1, B - 2, A, 3, 0, 1)
		term.setCursor(1, B - 2)
		term.clearLine()
		term.setCursor(x, B - 1)
		if message ~= myMessage then computer.beep(1000, 0.1) end
	end
end

function Sender()
	local result
	while true do 
		myMessage = term.read(nil, false)
		result = text.trim(myMessage)
		result = text.detab(result, 1)
		if result == "exit" then 
			term.clear()
			return 0 
		end
		if result ~= "" and unicode.len(myMessage) < 128 then 
			myMessage = string.format("%s: %s", name, myMessage)
			modem.send(serverAddress, primaryPort, myMessage) 
		end
		term.clearLine()
	end
end


modem.setStrength(5000)
local choiceResult = Choice()
if choiceResult ~= 0 then 
	primaryPort = choiceResult
	modem.open(primaryPort)
	A, B = gpu.getResolution()
	term.clear()
	term.setCursor(1, B - 1)
	thread.init()
	local handler = thread.create(Receiver)
	Sender()
	modem.close(choiceResult)
	thread.kill(handler)
	thread.waitForAll()
end