local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")

function init()
	config.TryBindKey("Ctrl-r", "lua:initlua.run", true)
	config.MakeCommand("cp", cp, config.NoComplete)
end

function run(bp)
	local buf = bp.Buf
	local path = buf.Path
	    
	if buf:FileType() == "html" then
		shell.RunCommand("chromium " .. buf.Path)
	elseif buf:FileType() == "go" then
		shell.RunInteractiveShell("go run " .. buf.Path, true, false)
	end
end

function extractCpMode(args)
	local mode = "";
	for i = 1, #args do
		mode = args[i]
	end
	return mode
end

function getDisplayServerType()
	local srv, err = shell.RunCommand("sh -c 'echo $XDG_SESSION_TYPE'")
	
	if err == nil and srv:len() > 0 then
		local strings = import("strings")
		srv = strings.TrimRight(srv, "\n")
		if srv:len() > 0 then
			return srv
		end
	end
	
	return "tty"
end

function cp(bp, args)
	local mode = extractCpMode(args)
	local path = bp.Buf.AbsPath

	if mode == "dir" then
		local fp = import("filepath")
		path = fp.Dir(path)
	end

	local srv = getDisplayServerType()
	if srv == "wayland" then
		cmd = "sh -c 'echo -n \""..path.."\" | wl-copy'"
	elseif srv == "tty" then
		cmd = "sh -c 'echo -n \""..path.."\" | osc52'"
	else
		cmd = "sh -c 'echo -n \""..path.."\" | xclip -selection clipboard'"
	end

	local output, err = shell.RunInteractiveShell(cmd, false, false)
	if err == nil then
		micro.InfoBar():Message("copied filepath.")
	else
		micro.InfoBar():Error(err)
	end
end
