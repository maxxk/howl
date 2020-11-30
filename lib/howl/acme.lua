local File = require('howl.io.file')
local acme = {}

function acme.plumb(args)
    local app_commands = howl.commands.app_commands
    local filename = args.text
    local colon = string.find(filename, ':')
    local sharp = string.find(filename, '#')
    local position = nil

    if colon then
        filename = string.sub(filename, 0, colon)
        position = string.sub(filename, colon+1)

    elseif sharp then
        filename = string.sub(filename, 0, sharp)
        position = string.sub(filename, sharp+1)
    end

    local file = File(filename)
    if not file.exists then
        file = File(app_commands.get_buffer_dir(howl.app.editor.buffer):join(filename))
    end
    if file.exists then
        if position then
            print("Should open file ", filename, " in position ", position)
        end
        if file.content_type:sub(1, #"text/") == "text/" then
            args.application:open_file(file)
        else
            print("Running", "xdg-open " .. file.basename)
            howl.io.Process.execute("xdg-open " .. file.basename, { working_directory = file.parent })
        end
    else -- TODO: try project root
        error("Unable to open file " .. filename)
    end
end

function acme.execute(args)
    local app_commands = howl.commands.app_commands
    local ok, cwd = pcall(app_commands.get_project_root)
    if not ok then
        cwd = app_commands.get_buffer_dir(howl.app.editor.buffer)
    end
    if not cwd then
        error("Unable to run command: unknown working dir")
    else
        app_commands.launch_cmd(cwd, args.text)
    end
end

return acme
