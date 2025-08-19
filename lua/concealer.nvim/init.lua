local utils = require("Concealer-nvim.utils")
local conceal = require("Concealer-nvim.conceal")
local state = require("Concealer-nvim.state")
local M = {}

local default_config = {
  default_conceal_symbol = "*",
  enabled_by_default = true,
  conceal_rules = {
  },
}

local enabled
local lookup_table
local config

---@param user_config table | nil
function M.setup(user_config)
  if user_config == nil then
    user_config = {}
  end
  utils.merge_table_impl(user_config, default_config)
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

function M.enable()
  enabled = true
  vim.wo.conceallevel = 1
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "WinScrolled" }, {
    group = state.augroup,
    desc = "Conceal updates",
    callback = function(args)
      local filetype = vim.bo[args.buf].filetype
      local conceal_rules = lookup_table[filetype]
      if not conceal_rules then
        return
      else
        for _, rule in pairs(conceal_rules) do
          local ts_parser_name = utils.get_ts_lang(filetype)
          conceal.apply_treesitter_conceal(args.buf, rule, ts_parser_name)
        end
      end
    end,
  })
end

function M.disable()
  enabled = false
  vim.api.nvim_clear_autocmds({ group = state.augroup })
end

function M.info()
  local info_to_display = {
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
