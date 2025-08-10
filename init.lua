local utils = require("Concealer-nvim.utils")
local conceal = require("Concealer-nvim.conceal")

local M = {}

local augroup = vim.api.nvim_create_augroup("Concealer-nvim", {
	clear = true,
})

local namespace = vim.api.nvim_create_namespace("Concealer-nvim")

-- Default config just here for now to iterate faster
--
--
local temp_config = {
	default_conceal_symbol = "*",
	enabled_by_default = true,
	conceal_rules = {
		{
			file_types = { "typescriptreact", "javascriptreact" },
			pattern = [[className="([^"]+)"]],
			target_capture_groups = { 1 },
			conceal_symbol = ".",
		},
		{
			file_types = { "typescriptreact", "javascriptreact" },
			treesitter_query = [[
    (jsx_attribute
      (property_identifier) @prop_name
      (string) @class_value
    )
    (#eq? @prop_name "className")    (#eq? @prop_name "className")
  ]],
			conceal_captures = { "class_value" },
			conceal_symbol = ".",
		},
	},
}

---@type boolean
local enabled

---@type table<string, ConcealRule[]>
local lookup_table
local config

---@param user_config table | nil
function M.setup(user_config)
	if user_config == nil then
		user_config = {}
	end
	utils.merge_table_impl(user_config, temp_config)
	config = user_config
	lookup_table = conceal.build_lookup_table(user_config)
	enabled = user_config.enabled_by_default

	if enabled then
		M.enable()
	end
end

function M.toggle()
	enabled = not enabled
	if enabled then
		M.enable()
	else
		M.disable()
	end
end

---@class ConcealRule
---@field file_types string[]      -- plural, matches your config field
---@field pattern? string          -- optional field, add `?` for optional
---@field target_capture_groups? integer[] -- optional
---@field conceal_symbol string
---@field treesitter_query? string -- optional
---@field conceal_captures? string[] -- optional

---@param conceal_rule ConcealRule
---@return boolean
local function is_treesitter_rule(conceal_rule)
	return conceal_rule.treesitter_query ~= nil
end

function M.enable()
	enabled = true
	vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
		group = augroup,
		desc = "Conceal updates",
		callback = function(args)
			if not enabled then
				return
			end
			local filetype = vim.bo[args.buf].filetype
			print(filetype)
			local conceal_rules = lookup_table[filetype]
			if not conceal_rules then
				return
			else
				for _, rule in pairs(conceal_rules) do
					if is_treesitter_rule(rule) then
						local ts_parser_name = utils.get_ts_lang(filetype)
						print(ts_parser_name)
						-- Treesitter based
						conceal.apply_treesitter_conceal(args.buf, rule, ts_parser_name)
					else
						-- Capture group based
					end
				end
			end
		end,
	})
end

function M.disable()
	enabled = false
	vim.api.nvim_clear_autocmds({ group = augroup })
end

function M.info()
	local ok = pcall(require, "nvim-treesitter.configs")
	local info_to_display = {
		treesitter_installed = ok,
		enabled = enabled,
		config = config,
		lookup_table = lookup_table,
	}

	local lines = vim.split(vim.inspect(info_to_display), "\n")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "lua"
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_name(buf, "Concealer-nvim info")
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close!<CR>", {
		noremap = true,
		silent = true,
		desc = "Close info window",
	})

	vim.cmd("tabnew")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
end

return M
