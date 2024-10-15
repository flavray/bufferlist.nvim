local api = vim.api

local WIDTH = 80

local _window = nil
local _buffers = nil

--- Helpers ---

local function list_buffers()
	return vim.tbl_map(
		function(b)
			return { handle = b, name = api.nvim_buf_get_name(b) }
		end,
		vim.tbl_filter(function(b)
			return api.nvim_buf_is_valid(b) and api.nvim_get_option_value("buflisted", { buf = b })
		end, api.nvim_list_bufs())
	)
end

local function goto_buffer(buffer)
	api.nvim_command("b " .. buffer)
end

local function string_with_length(string, length)
	if string:len() > length then
		local prefix = "..."
		return prefix .. string:sub(-length + prefix:len())
	else
		return string .. string.rep("·", length - string:len())
	end
end

local function pretty_buffer_name(buffer)
	local current_directory = vim.fn.getcwd() .. "/"
	local name = buffer.name

	if name:sub(1, current_directory:len()) == current_directory then
		name = name:sub(current_directory:len() + 1)
	end

	return string_with_length(name, WIDTH - 2) .. "··"
end

---

local function close()
	if _window ~= nil then
		api.nvim_win_close(_window, true)
		_window = nil
		_buffers = nil
	end
end

local function create_buffer(lines)
	local buffer = api.nvim_create_buf(false, true)

	api.nvim_set_option_value("bufhidden", "wipe", { buf = buffer })
	api.nvim_set_option_value("filetype", "bufferlist", { buf = buffer })

	api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	api.nvim_set_option_value("modifiable", false, { buf = buffer })

	return buffer
end

local function create_window(buffer, selected_line)
	local ui = api.nvim_list_uis()[1]

	local window_config = {
		relative = "editor",
		width = WIDTH,
		height = ui.height - 20,
		col = (ui.width / 2) - (WIDTH / 2),
		row = 10,
		style = "minimal",
	}

	local window = api.nvim_open_win(buffer, true, window_config)

	api.nvim_set_option_value("cursorline", true, { win = window })

	if selected_line ~= nil then
		api.nvim_win_set_cursor(window, { selected_line, 0 })
	end

	return window
end

local function setup_mappings(buffer)
	api.nvim_buf_set_keymap(
		buffer,
		"n",
		"<esc>",
		":lua require('bufferlist-nvim').close()<cr>",
		{ noremap = true, silent = true }
	)

	api.nvim_buf_set_keymap(
		buffer,
		"n",
		"<cr>",
		":lua require('bufferlist-nvim').select()<cr>",
		{ noremap = true, silent = true }
	)
end

local function open()
	local current_buffer = api.nvim_get_current_buf()

	local lines = {}
	local selected = nil

	_buffers = list_buffers()

	for i, buffer in pairs(_buffers) do
		lines[i] = pretty_buffer_name(buffer)

		if buffer.handle == current_buffer then
			selected = i
		end
	end

	local buffer = create_buffer(lines)
	setup_mappings(buffer)

	_window = create_window(buffer, selected)
end

local function select()
	if _window == nil or _buffers == nil then
		return
	end

	local row = api.nvim_win_get_cursor(_window)[1]
	local selected = _buffers[row].handle

	close()
	goto_buffer(selected)
end

local function toggle()
	if _window == nil or not api.nvim_win_is_valid(_window) then
		open()
	else
		close()
	end
end

return { toggle = toggle, close = close, select = select }
