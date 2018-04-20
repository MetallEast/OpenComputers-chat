-- thread.lua code is written by Zer0Galaxy
-- Code: http://pastebin.com/E0SzJcCx

local thread = require("thread")
local computer = require("computer")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local text = require("text")
local term = require("term")
local unicode = require("unicode")
local gpu = component.gpu

local modem, serverAddress, primaryPort
local name, myMessage
local A, B
local sHandler, rHandler

local function Registration()
	local nickname, password, repetition, _, _, address, _, _, message
	term.clear()
	term.write("User: ") nickname = text.trim(term.read())
	term.write("Password: ")           password = text.trim(term.read(nil, true, nil, "*"))
	term.write("Repeat password: ") repetition = text.trim(term.read(nil, true, nil, "*"))
	if password ~= repetition then 
		term.write("\nThe passwords do not match")
		os.sleep(0.5)
	else 
		local user = {[1] = nickname, [2] = password}
		local packet = serialization.serialize(user)
		modem.open(255)
		modem.send(serverAddress, 255, packet)
		while address ~= serverAddress do
			_, _, address, _, _, message = event.pull("modem_message")
		end
		modem.close(255)
		if type(message) == "number" then
			term.clear()
			print("Registration complete")
		else print(message) end
	end
	event.pull("key_up") 
	term.clear()
end

local function Authentication()
	local nickname, password, _, _, address, _, _, message
	term.write("User: ") nickname = text.trim(term.read())
	term.write("Password: ") password = text.trim(term.read(nil, true, nil, "*"))
	local user = {[1] = nickname, [2] = password}
	local packet = serialization.serialize(user)
	modem.open(256)
	modem.send(serverAddress, 256, packet)
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

local function Choice()
	while true do
		print("1. Chat\n2. Registration\n3. Exit\n")
		local _, _, _, choice = event.pull("key_up") 
		term.clear()
		if choice == 2 then 
			local authResult = Authentication() 
			if authResult ~= 0 then return authResult end
		end
		if choice == 3 then Registration() end
		if choice == 4 then break end
	end
	return 0
end

local function Receiver()
	local x, y		
	local _, _, address, port, _, message, mesHeight
	local chatWidth = math.floor(A * 0.75)
	local onlineLeftBorder = math.floor(A * 0.8) - 1
	local onlineWidth = math.floor(A * 0.2) - 1
	local onlineCenter = math.floor(A * 0.9) - 1
	local online = {}
	while true do
		_, _, address, port, _, message = event.pull("modem_message")
		if address == serverAddress then
			address = nil
			if port == 253 then
				if message == 'P' then modem.send(serverAddress, 253, name)
				else online = serialization.unserialize(message) end
			else	   
				if message == 'R' or message == 'C' then
					term.setCursor(1, B - 3)
					if message == 'R' then print(" [Server] Restarting...")
					else print(" [Server] Shutting down...") end
					thread.kill(sHandler)
					term.setCursorBlink(false)
					os.sleep(3) 
					term.clear()
					break
				else
					x, y = term.getCursor()
					local unsent = ''
					for i=2, x, 1 do unsent = unsent .. gpu.get(i, y) end
					gpu.fill(1, B - 2, A, 3, " ") -- clear input textbox
					-- move chat up
					mesHeight = math.floor(unicode.len(message) / chatWidth) + 1
					for i=1, mesHeight, 1 do
						term.setCursor(A, B)
						term.write(' ', true)
					end
					term.setCursor(1, B - 3 - mesHeight)
					-- print message
					message = text.trim(message)
					while true do
						if unicode.len(message) < chatWidth then print(' ' .. message) break end
						print(' ' .. unicode.sub(message, 1, chatWidth))
						message = unicode.sub(message, chatWidth + 1)
					end		
					-- online list
					gpu.setForeground(0xffffff)
					gpu.setBackground(0x008000)
					gpu.fill(onlineLeftBorder, 1, onlineWidth, 3, " ")
					term.setCursor(onlineCenter - 3, 2) term.write("ONLINE")	
					gpu.setForeground(0x000000)
					gpu.setBackground(0xffffff)
					gpu.fill(onlineLeftBorder, 4, onlineWidth, B - 7, " ")
					for i=1,#online,1 do
						term.setCursor(onlineLeftBorder, i+4) 
						term.write(' ' .. online[i])
					end
					gpu.setForeground(0xffffff)
					gpu.setBackground(0x000000)
					-- input field
					gpu.fill(1, B, A, 1, "—")
					gpu.fill(1, B - 2, A, 1, "—")
					-- setting cursor to start position
					term.setCursor(2, B - 1) print(unsent)
					term.setCursor(x, B - 1)
					if message ~= myMessage then computer.beep(1000, 0.1) end
				end
			end
		end
	end
end

local function Sender()
	local result
	local history = {}
	while true do 
		term.setCursor(2, B - 1) 
		myMessage = term.read(history, false)
		result = text.trim(myMessage)
		result = text.detab(result, 1)
		if result == "exit" then 
			term.clear()
			thread.kill(rHandler)
			break
		end
		if unicode.len(result) > 0  and unicode.len(result) < 256 then 
			myMessage = name .. ": " .. myMessage
			modem.send(serverAddress, primaryPort, myMessage)
		end
		term.clearLine()
		if #history > 5 then table.remove(history, 1) end
	end
end

local function CheckModem()
	if component.isAvailable("modem") == false then return 0 end
	modem = component.modem
	modem.setStrength(5000)
	return 1
end

local function CheckConnection()
	if CheckModem() == 0 then 
		print("Wireless card not found") return 0 end
	local serverOn = false
	term.clear()
	term.write("Connecting")
	modem.open(254)
	for try = 1, 3 do
		modem.broadcast(254, 1)
		local _, _, address, _, _, _ = event.pull(3, "modem_message")
		if address ~= nil then
			serverAddress = address
			serverOn = true
			break
		end
		term.write(".")
	end
	modem.close(254)
	term.clear()
	if serverOn == true then return 1 end
	print("The server is not available")
	return 0
end

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
		print("You're banned on this server") end
else
	os.sleep(0.5)
	event.pull("key_up")
	term.clear()
end
