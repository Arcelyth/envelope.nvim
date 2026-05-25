local M = {}

local config = {
	host = "127.0.0.1",
	port = 10824,
	warning_color = { 227, 212, 98 },
	error_color = { 224, 93, 70 },
	info_color = { 79, 201, 194 },
	hint_color = { 79, 201, 148 },
	id = "envelope.nvim",
	treesitter = true,
	treesitter_color = { 124, 186, 196 },
	diag = true,
	use = true,
    debounce_time = 50,
}

local uv = vim.loop

local udp = uv.new_udp()

local augroup = vim.api.nvim_create_augroup("DiagnosticSender", { clear = true })

function M.get_diag()
	local line, _col = unpack(vim.api.nvim_win_get_cursor(0))
	local diags = vim.diagnostic.get(0, { lnum = line - 1 })
	return diags
end

function M.get_diag_info(msg_list)
	local diags = M.get_diag()
	for _, diag in ipairs(diags) do
		local color = config.warning_color

		if diag.severity == vim.diagnostic.severity.WARN then
			color = config.warning_color
		elseif diag.severity == vim.diagnostic.severity.ERROR then
			color = config.error_color
		elseif diag.severity == vim.diagnostic.severity.HINT then
			color = config.hint_color
		elseif diag.severity == vim.diagnostic.severity.INFO then
			color = config.info_color
		end

		table.insert(msg_list, { config.id .. "_diag" .. tostring(diag.col), diag.message, color })
	end
end

function M.get_treesitter_node_type(msg_list)
	local node = vim.treesitter.get_node()

	if not node then
		return
	end

	local node_type = node:type()

	table.insert(msg_list, {
		config.id .. "_treesitter",
		node_type,
		config.treesitter_color,
	})
end

local last_ids = {}

function M.send_packet(data)
	local json = vim.json.encode(data)

	udp:send(json, config.host, config.port, function(err)
		if err then
			vim.schedule(function()
				print("udp error:", err)
			end)
		end
	end)
end

function M.send_to_port()
	local msg_list = {}
	local current_ids = {}

	if config.diag then
		M.get_diag_info(msg_list)
	end
	if config.treesitter then
		M.get_treesitter_node_type(msg_list)
	end

	for _, info in ipairs(msg_list) do
		current_ids[info[1]] = true
		M.send_packet({
			id = info[1],
			content = info[2],
			max_width = 50,
			max_height = 20,
			duration = 10.0,
			color = info[3],
			show = true,
		})
	end
	for id, _ in pairs(last_ids) do
		if not current_ids[id] then
			M.send_packet({
				id = id,
				content = "",
				max_width = 0,
				max_height = 0,
				duration = 0,
				color = config.hint_color,
				show = false,
			})
		end
	end

	last_ids = current_ids
end

local last_line = vim.fn.line(".")

local timer = uv.new_timer()

local function enable_autocmd()
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		callback = function()
			local current_line = vim.fn.line(".")

			if current_line ~= last_line then
				last_line = current_line
				
				timer:stop()
				timer:start(config.debounce_time, 0, vim.schedule_wrap(function()
					M.send_to_port()
				end))
			end
		end,
	})
end

local function disable_autocmd()
	vim.api.nvim_clear_autocmds({
		group = augroup,
	})
end

function M.switch()
	config.use = not config.use

	if config.use then
		enable_autocmd()
	else
		disable_autocmd()
	end
end

function M.setup(opts)
	if opts then
		config = vim.tbl_extend("force", config, opts)
	end

	if config.use then
		enable_autocmd()
	end

	vim.api.nvim_create_user_command("EnvelopeSwitch", function()
		M.switch()
	end, {})
end

return M
