local M = {}

function M.merge_table_impl(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k]) == "table" then
				M.merge_table_impl(t1[k], v)
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
end

function M.table_to_string(tbl, indent)
	indent = indent or 0
	local lines = {}
	local padding = string.rep("  ", indent)

	table.insert(lines, "{")
	for k, v in pairs(tbl) do
		local key = "[" .. tostring(k) .. "]"
		if type(v) == "table" then
			table.insert(lines, padding .. "  " .. key .. " = " .. M.table_to_string(v, indent + 1) .. ",")
		else
			table.insert(lines, padding .. "  " .. key .. " = " .. tostring(v) .. ",")
		end
	end
	table.insert(lines, padding .. "}")
	return table.concat(lines, "\n")
end

function M.table_to_array(tbl, indent)
	indent = indent or 0
	local lines = {}
	local padding = string.rep("  ", indent)

	table.insert(lines, "{")
	for k, v in pairs(tbl) do
		local key = "[" .. tostring(k) .. "]"
		if type(v) == "table" then
			table.insert(
				lines,
				padding .. "  " .. key .. " = " .. table.concat(M.table_to_array(v, indent + 1), "\n") .. ","
			)
		else
			table.insert(lines, padding .. "  " .. key .. " = " .. tostring(v) .. ",")
		end
	end
	table.insert(lines, padding .. "}")
	return lines
end

local parser_for_filetype = {
	javascript = "javascript",
	typescript = "typescript",
	javascriptreact = "javascript",
	typescriptreact = "tsx",
	html = "html",
	css = "css",
	scss = "scss",
	less = "less",
	markdown = "markdown",
	json = "json",
	toml = "toml",
	yaml = "yaml",
	sh = "bash",
	zsh = "bash",
	lua = "lua",
	python = "python",
	ruby = "ruby",
	go = "go",
	rust = "rust",
	java = "java",
	kotlin = "kotlin",
	cpp = "cpp",
	c = "c",
	cmake = "cmake",
	dart = "dart",
	php = "php",
	sql = "sql",
	vim = "vim",
	make = "make",
	jsonc = "jsonc",
}

-- Some names differ from :set filetype? to treesitter language parsers
-- Convert filetype to treesitter format e.g. typescriptreact -> tsx
function M.get_ts_lang(ft)
	return parser_for_filetype[ft] or ft
end

return M
