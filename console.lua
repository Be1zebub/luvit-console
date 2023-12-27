-- from gmod.one with <3
-- put it in your libs/console.lua

local function string_split(pString, pPattern)
	local tbl = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find(fpat, 1)

	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(tbl, cap)
		end

		last_end = e + 1
		s, e, cap = pString:find(fpat, last_end)
	end

	if last_end <= #pString then
		cap = pString:sub(last_end)
		table.insert(tbl, cap)
	end

	return tbl
end

local concommand = {}
concommand.list = {}
concommand.alias_list = {}

function concommand.Add(name, cback, helpText, alias)
	local cmd = {
		cback = cback,
		help = helpText or "unspecified",
		aliases = alias and (type(alias) == "table" and alias or {alias}) or nil
	}
	concommand.list[name] = cmd

	if alias == nil then return cmd end

	if type(alias) == "table" then
		for _, a in ipairs(alias) do
			concommand.alias_list[a] = cmd
		end
	else
		concommand.alias_list[alias] = cmd
	end

	return cmd
end

function concommand.Remove(name)
	local cmd = concommand.list[name]

	if cmd then
		concommand.list[name] = nil
		if cmd.aliases == nil then return end

		for _, alias in ipairs(cmd.aliases) do
			concommand.alias_list[alias] = nil
		end
	elseif concommand.alias_list[name] then
		concommand.alias_list[name] = nil
	end
end

local repl

do
	local Editor = require("readline").Editor

	function repl(onLine, autocomplete, stdin, stdout)
		local editor = Editor.new({
		  stdin = stdin or process.stdin.handle,
		  stdout = stdout or process.stdout.handle,
		  completionCallback = autocomplete
		})

		local prompt = "> "

		local function ReadLine(err, line)
			assert(not err)
			coroutine.wrap(function()
				if line == false then return end -- handle intr aka sigint aka control+c (not sure if this right way, but it works...)
				prompt = onLine(line) or "> "
				editor:readLine(prompt, ReadLine)
			end)()
		end

		editor:readLine(prompt, ReadLine)
		return editor
	end
end

repl(function(str)
	local args = string_split(str, " ")
	local arg_1st = table.remove(args, 1)
	if arg_1st == nil then return end

	local cmd = concommand.list[arg_1st] or concommand.alias_list[arg_1st]
	if not cmd then
		print(" - unknown-concommand: `".. arg_1st .."`")
		return
	end

	cmd.cback(args, table.concat(args))
end, function(str)
	local search = "^".. str:lower() ..".-"
	local found = {}

	for k in pairs(concommand.list) do
		if k:lower():match(search) then
			found[#found + 1] = k
		end
	end

	if #found == 1 then
		return found[1]
	elseif #found > 1 then
		return found
	end
end)

local function showHelp(name, cmd)
	print(name .." - ".. cmd.help)
	if cmd.aliases then
		print("\taliases: ".. table.concat(cmd.aliases, ", "))
	end
end

concommand.Add("help", function(_, argStr)
	local cmd = concommand.list[argStr] or concommand.alias_list[argStr]

	if cmd then
		showHelp(argStr, cmd)
	else
		for name, cmd2 in pairs(concommand.list) do
			showHelp(name, cmd2)
		end
	end
end, "Prints help about a concommand.")

concommand.Add("run", function(_, code)
	local succ, fn, syntaxError = pcall(load, code, "concommand \"run\"", "t")
	if succ == false or not fn then return error(syntaxError) end

	local success, runtimeError = pcall(fn)
	if not success then error(runtimeError) end
end, "Runs lua", {"lua_run", "runstring", "eval"})

concommand.Add("clear", function()
	print("\x1Bc")
end, "Clears console", "clean")

do
	local start = os.time()

	local function FormatTime(seconds)
		if seconds == nil or seconds <= 0 then return string.format("00:00") end

		local hours = math.floor(seconds / 3600)
		local minutes = math.floor(seconds / 60) % 60
		seconds = seconds % 60

		if hours < 1 then
			return string.format("%.2i:%.2i", minutes, seconds)
		end

		return string.format("%.2i:%.2i:%.2i", hours, minutes, seconds)
	end

	concommand.Add("uptime", function()
		local delta = os.time() - start

		print(FormatTime(delta))
	end, "Shows app uptime")
end

return concommand
