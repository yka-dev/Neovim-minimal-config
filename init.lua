-- ========================================================================== --
--                    GLOBAL USER CONFIGURATION SECTION                       --
-- ========================================================================== --
local CONFIG = {
	lsp_servers = {
		"lua_ls",
		"clangd",
		"pyright",
		"vtsls",
		"ols",
		"jsonls",
	},
	formatters = {
		"stylua",
		"clang-format",
		"black",
		"prettierd",
	},
	tab_size = 4,
	line_numbers = true,
	relative_lines = true,
	keymaps = {
		leader = " ",
		open_file_manager = "-",
		find_files = "<leader>ff",
		live_grep = "<leader>fg",
		find_buffers = "<leader>fb",
		format_file = "<leader>fm",
		toggle_diagnostics = "<leader>xx",
		lsp_go_to_definition = "gd",
		lsp_hover_docs = "K",
		lsp_rename_symbol = "<leader>rn",
	},
}

-- ========================================================================== --
-- 1. APPLY BASIC SETTINGS & TRANSPARENCY
-- ========================================================================== --
vim.g.mapleader = CONFIG.keymaps.leader
vim.g.maplocalleader = CONFIG.keymaps.leader

vim.opt.number = CONFIG.line_numbers
vim.opt.relativenumber = CONFIG.relative_lines
vim.opt.shiftwidth = CONFIG.tab_size
vim.opt.tabstop = CONFIG.tab_size
vim.opt.expandtab = true

local function apply_transparency()
	vim.cmd([[
      highlight Normal guibg=none ctermbg=none
      highlight NonText guibg=none ctermbg=none
      highlight NormalNC guibg=none ctermbg=none
      highlight SignColumn guibg=none ctermbg=none
      
      highlight NormalFloat guibg=none ctermbg=none
      highlight FloatBorder guibg=none ctermbg=none
      highlight WinBar guibg=none ctermbg=none
      highlight WinBarNC guibg=none ctermbg=none
      
      highlight SplitKeep guibg=none ctermbg=none
      highlight EndOfBuffer guibg=none ctermbg=none
    ]])
end
apply_transparency()
vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_transparency })

-- ========================================================================== --
-- 2. BOOTSTRAP LAZY.NVIM
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- ========================================================================== --
-- 3. PLUGINS CONFIGURATION
-- ========================================================================== --
require("lazy").setup({

	-- Theme: Kanagawa 
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				transparent = true,
				theme = "dragon",
				colors = {
					theme = {
						all = {
							ui = {
								bg_gutter = "none",
							},
						},
					},
				},
			})
			vim.cmd("colorscheme kanagawa")
		end,
	},

	-- Oil.nvim
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Oil",
        lazy = false,
		keys = { { CONFIG.keymaps.open_file_manager, "<CMD>Oil<CR>", desc = "Open parent directory" } },
		config = function()
			require("oil").setup({ view_options = { show_hidden = true } })
		end,
	},

	-- Telescope.nvim (Lazy loaded on command call or keymap execution)
	{
		"nvim-telescope/telescope.nvim",
		branch = "master",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{
				CONFIG.keymaps.find_files,
				function()
					require("telescope.builtin").find_files(require("telescope.themes").get_ivy())
				end,
				desc = "Find Files",
			},
			{
				CONFIG.keymaps.live_grep,
				function()
					require("telescope.builtin").live_grep(require("telescope.themes").get_ivy())
				end,
				desc = "Live Grep",
			},
			{
				CONFIG.keymaps.find_buffers,
				function()
					require("telescope.builtin").buffers(require("telescope.themes").get_ivy())
				end,
				desc = "Find Buffers",
			},
		},
		config = function()
			require("telescope").setup({
				defaults = {
					preview = false,
					layout_strategy = "bottom_pane",
					layout_config = { height = 15 },
					sorting_strategy = "ascending",
					border = true,
				},
			})
		end,
	},

	-- Nvim-Treesitter (Lazy loaded when a buffer reads a file)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter").setup({
				auto_install = true,
				sync_install = false,
				highlight = { enable = true, additional_vim_regex_highlighting = false },
			})
		end,
	},

	-- Nvim-ts-autotag (Lazy loaded strictly inside markup/script file types)
	{
		"windwp/nvim-ts-autotag",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "html", "javascript", "typescript", "javascriptreact", "typescriptreact", "xml" },
		config = function()
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
			})
		end,
	},

	-- Snippet Engine (Lazy loaded when autocompletion environment initiates)
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		lazy = true,
		config = function()
			local luasnip = require("luasnip")
			luasnip.filetype_extend("javascriptreact", { "html" })
			luasnip.filetype_extend("typescriptreact", { "html" })
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Conform.nvim (Lazy loaded on format execution or file adjustments)
	{
		"stevearc/conform.nvim",
		keys = {
			{
				CONFIG.keymaps.format_file,
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format Buffer",
			},
		},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					c = { "clang-format" },
					cpp = { "clang-format" },
					python = { "black" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					javascriptreact = { "prettierd" },
					typescriptreact = { "prettierd" },
					json = { "prettierd" },
				},
			})
		end,
	},

	-- Nvim-cmp (Lazy loaded when entering Insert mode)
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			"saadparwaiz1/cmp_luasnip",
			"L3MON4D3/LuaSnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer" },
				}),
			})
		end,
	},

	-- Nvim-lspconfig (Lazy loaded when code files are actively loaded into buffers)
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("mason").setup()

			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = CONFIG.lsp_servers,
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end,
				},
			})

			require("mason-tool-installer").setup({ ensure_installed = CONFIG.formatters })

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(event)
					local opts = { buffer = event.buf }
					vim.keymap.set("n", CONFIG.keymaps.lsp_go_to_definition, vim.lsp.buf.definition, opts)
					vim.keymap.set("n", CONFIG.keymaps.lsp_hover_docs, vim.lsp.buf.hover, opts)
					vim.keymap.set("n", CONFIG.keymaps.lsp_rename_symbol, vim.lsp.buf.rename, opts)

					vim.keymap.set("n", CONFIG.keymaps.toggle_diagnostics, function()
						local qf_exists = false
						for _, win in pairs(vim.fn.getwininfo()) do
							if win.quickfix == 1 then
								qf_exists = true
							end
						end
						if qf_exists then
							vim.cmd("cclose")
						else
							vim.diagnostic.setqflist({ open = true })
						end
					end, opts)
				end,
			})
		end,
	},
})
