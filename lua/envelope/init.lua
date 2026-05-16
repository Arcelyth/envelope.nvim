local M = {}

local config = {
	host = "127.0.0.1",
	port = 10824,
	warning_color = { 227, 212, 98 },
	error_color = { 224, 93, 70 },
	info_color = { 79, 201, 194 },
	hint_color = { 79, 201, 148 },
	id = "envelope.nvim",
	use = true,
}

local uv = vim.loop

local udp = uv.new_udp()

local augroup = vim.api.nvim_create_augroup("DiagnosticSender", { clear = true })

function M.get_diag()
	local line, _col = unpack(vim.api.nvim_win_get_cursor(0))
	local diags = vim.diagnostic.get(0, { lnum = line - 1 })
	return diags
end

function M.get_diag_info()
	local diags = M.get_diag()
	local ret = {}
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

		table.insert(ret, { diag.message, color })
	end
	return ret
end

function M.send_to_port()
	local infos = M.get_diag_info()

	local data

	if #infos == 0 then
		data = {
			id = config.id,
			content = "",
			max_width = 50,
			max_height = 20,
			duration = 10.0,
			color = config.hint_color,
			show = false,
		}

		local json = vim.json.encode(data)
		udp:send(json, config.host, config.port, function(err)
			if err then
				print("udp error", err)
			end
		end)
	else
		for _, info in ipairs(infos) do
			data = {
				id = config.id,
				content = info[1],
				max_width = 50,
				max_height = 20,
				duration = 10.0,
				color = info[2],
				show = true,
			}

			local json = vim.json.encode(data)

			udp:send(json, config.host, config.port, function(err)
				if err then
					print("udp error", err)
				end
			end)
		end
	end
end

local function enable_autocmd()
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorHold" }, {
		group = augroup,
		callback = function()
			M.send_to_port()
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
