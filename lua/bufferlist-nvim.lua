local api = vim.api

local WIDTH = 80

local _window = nil

--- Helpers ---

local function list_buffers()
	return vim.tbl_filter(function(b)
		return api.nvim_buf_is_valid(b) and api.nvim_get_option_value("buflisted", { buf = b })
	end, api.nvim_list_bufs())
end

local function goto_buffer(buffer)
	api.nvim_command("b " .. buffer)
end

---

local function close()
	if _window ~= nil then
		api.nvim_win_close(_window, true)
		_window = nil
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

	for i, b in pairs(list_buffers()) do
		lines[i] = api.nvim_buf_get_name(b)

		if b == current_buffer then
			selected = i
		end
	end

	local buffer = create_buffer(lines)
	setup_mappings(buffer)

	_window = create_window(buffer, selected)
end

local function select()
	local selected_name = api.nvim_get_current_line()
	local selected = nil

	for _, b in pairs(list_buffers()) do
		local name = api.nvim_buf_get_name(b)
		if name == selected_name then
			selected = b
			break
		end
	end

	if selected ~= nil then
		close()
		goto_buffer(selected)
	end
end

local function toggle()
	if _window == nil or not api.nvim_win_is_valid(_window) then
		open()
	else
		close()
	end
end

return { toggle = toggle, close = close, select = select }
