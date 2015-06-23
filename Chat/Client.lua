local thread = require("thread")
local computer = require("computer")
local component = require("component")
local term = require("term")
local text = require("text")
local serialization = require("serialization")
local event = require("event")
local modem = component.modem
local gpu = component.gpu

local registrationLevel   = "9f54fd85-eec4-4d75-8830-0924570d54bc"
local authenticationLevel = "9ed56ccb-b4c4-4dba-bb2d-50dccb844942"			
local primaryLevel	  = "79c5fa93-e6bd-4e97-80cc-193c4b6a1898"
local primaryPort
local myMessage
local A, B
local name

function Authentication()
	term.write("Имя пользователя: ")
	local nickname = text.trim(term.read())
	term.write("Пароль: ")
	local password = text.trim(term.read())
	
	local user = {}
	user[1] = nickname
	user[2] = password
	
	local packet = serialization.serialize(user)
	modem.open(256)
	modem.send(authenticationLevel, 256, packet)
	local _, _, address, _, _, message = event.pull("modem_message")
	modem.close(256)
	if type(message) == "number" then 
		name = nickname
		return message
	else 
		print(message)
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
	local password = text.trim(term.read())
	term.write("Повторите пароль: ")
	local repetition = text.trim(term.read())
	if password ~= repetition or string.len(password) < 3 or string.len(password) > 10 then 
		term.write("\nПароль должен быть в диапазоне от 3 до 10 символов")
		term.write("\nЗначения полей 'Пароль' и 'Повтор пароля' должны совпадать")
		os.sleep(1)
	else 
		user[1] = nickname
		user[2] = password
		local packet = serialization.serialize(user)
		modem.open(255)
		modem.send(registrationLevel, 255, packet)
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
		print("3. Выход")
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
		while address ~= primaryLevel do
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
	local ddot = ": "
	while true do 
		myMessage = term.read(nil, false)
		result = text.trim(myMessage)
		result = text.detab(result, 1)
		if result == "exit" then return 0 end
		if result ~= "" and string.len(myMessage) < 256 then 
			myMessage = string.format("%s%s%s", name, ddot, myMessage)
			modem.send(primaryLevel, primaryPort, myMessage) 
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