local M = {}

M.namespace = vim.api.nvim_create_namespace("Concealer-nvim")
M.augroup = vim.api.nvim_create_augroup("Concealer-nvim", {
	clear = true,
})

return M
