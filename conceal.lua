local M = {}

local function shallow_copy_without_file_types(rule)
	local copy = {}
	for k, v in pairs(rule) do
		if k ~= "file_types" then
			copy[k] = v
		end
	end
	return copy
end

function M.build_lookup_table(config)
	local lookup = {}
	for _, rule in ipairs(config.conceal_rules or {}) do
		for _, ft in ipairs(rule.file_types or {}) do
			lookup[ft] = lookup[ft] or {}
			table.insert(lookup[ft], shallow_copy_without_file_types(rule))
		end
	end
	return lookup
end
local ts = vim.treesitter

function M.apply_treesitter_conceal(bufnr, user_rule, parser_name)
	print(vim.inspect(user_rule), parser_name)
	local parser = ts.get_parser(bufnr, parser_name)
	if parser == nil then
		print("Parser is nil")
		return
	end
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = ts.query.parse(parser_name, user_rule.treesitter_query)
	local ns = vim.api.nvim_create_namespace("concealer-nvim")
	print(vim.inspect(query.captures))
	for id, node, _ in query:iter_captures(root, bufnr, 0, -1) do
		local capture_name = query.captures[id]
		if vim.tbl_contains(user_rule.conceal_captures, capture_name) then
			local start_row, start_col, end_row, end_col = node:range()
			-- Apply conceal in buffer at this range using user_rule.conceal_symbol
			vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				conceal = user_rule.conceal_symbol or "*",
			})
		end
	end
end

return M
