# luvit-console
A console commands repl for luvit.  
An tool for manage your bots, web services, or any other applications.  
![WindowsTerminal_l8fTTdMUq0](https://github.com/Be1zebub/luvit-console/assets/34854689/2f4f4a1e-dc1f-4fbd-8e68-22327177b39c)
  
  
### To use it in your project:
1. put lib in `libs/console.lua`
2. require it
```lua
require("console")
```
3. add custom commands
```lua
local concommand = require("console")

concommand.Add("1 + 1", function()
    print("2")
end, "Have you forgotten how much is 1 + 1?")

concommand.Add("unittest", function(args, argsStr)
    local test = unittests[argsStr] or unittests[args[1]]
    if test == nil then print("test not found!") return end

    test()
end, "Trigger unit-tests!", {"unit-test", "test", "unit"})
```
4. have fun <3
  
  
### API:
`concommand.list[name]`, `concommand.alias_list[aliasName]`  
`local cmd = concommand.Add(name, cback, helpText, alias)`  
`concommand.Remove(name)`
