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
        find_files   = "<leader>ff",
        live_grep    = "<leader>fg",
        find_buffers = "<leader>fb",
        format_file  = "<leader>fm",
        toggle_diagnostics = "<leader>xx", 
        lsp_go_to_definition = "gd",
        lsp_hover_docs       = "K",
        lsp_rename_symbol    = "<leader>rn",
    }
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

-- Global transparency engine covering windows, splits, and floating panels
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
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ========================================================================== --
-- 3. PLUGINS CONFIGURATION
-- ========================================================================== --
require("lazy").setup({

    -- Theme: Alabaster
    {
        'p00f/alabaster.nvim',
        config = function()
            vim.g.alabaster_transparent = true
            vim.cmd('colorscheme alabaster')
        end
    },

    -- Oil.nvim
    {
        'stevearc/oil.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require("oil").setup({ view_options = { show_hidden = true } })
            vim.keymap.set("n", CONFIG.keymaps.open_file_manager, "<CMD>Oil<CR>")
        end
    },

    -- Telescope.nvim
    {
        'nvim-telescope/telescope.nvim',
        branch = 'master',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local telescope = require('telescope')
            local builtin = require('telescope.builtin')

            telescope.setup({
                defaults = {
                    preview = false,            
                    layout_strategy = "bottom_pane", 
                    layout_config = { height = 15 },
                    sorting_strategy = "ascending", 
                    border = true,
                }
            })

            vim.keymap.set('n', CONFIG.keymaps.find_files, function() builtin.find_files(require('telescope.themes').get_ivy()) end)
            vim.keymap.set('n', CONFIG.keymaps.live_grep, function() builtin.live_grep(require('telescope.themes').get_ivy()) end)
            vim.keymap.set('n', CONFIG.keymaps.find_buffers, function() builtin.buffers(require('telescope.themes').get_ivy()) end)
        end
    },

    -- Nvim-Treesitter
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.config').setup({
                auto_install = true, 
                sync_install = false,
                highlight = { enable = true, additional_vim_regex_highlighting = false },
            })
        end
    },

    -- Conform.nvim
    {
        'stevearc/conform.nvim',
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
            vim.keymap.set("n", CONFIG.keymaps.format_file, function()
                require("conform").format({ async = true, lsp_fallback = true })
            end)
        end
    },

    -- Nvim-cmp
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp', 
            'hrsh7th/cmp-path',     
            'hrsh7th/cmp-buffer',   
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(), 
                    ['<CR>'] = cmp.mapping.confirm({ select = true }), 
                    ['<Tab>'] = cmp.mapping.select_next_item(),        
                    ['<S-Tab>'] = cmp.mapping.select_prev_item(),    
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' }, 
                    { name = 'path' },     
                    { name = 'buffer' },   
                })
            })
        end
    },

    -- Nvim-lspconfig
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',
            'hrsh7th/cmp-nvim-lsp', 
        },
        config = function()
            require("mason").setup()
            
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            require("mason-lspconfig").setup({
                ensure_installed = CONFIG.lsp_servers, 
                handlers = {
                    function(server_name)
                        require("lspconfig")[server_name].setup({
                            capabilities = capabilities, 
                        })
                    end,
                }
            })

            require("mason-tool-installer").setup({ ensure_installed = CONFIG.formatters })

            -- Attaches keymaps dynamically only when an active LSP server hooks into the buffer
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(event)
                    local opts = { buffer = event.buf }
                    vim.keymap.set('n', CONFIG.keymaps.lsp_go_to_definition, vim.lsp.buf.definition, opts)     
                    vim.keymap.set('n', CONFIG.keymaps.lsp_hover_docs, vim.lsp.buf.hover, opts)           
                    vim.keymap.set('n', CONFIG.keymaps.lsp_rename_symbol, vim.lsp.buf.rename, opts) 
                    
                    -- Native Error Panel Toggle (Quickfix List)
                    vim.keymap.set('n', CONFIG.keymaps.toggle_diagnostics, function()
                        local qf_exists = false
                        for _, win in pairs(vim.fn.getwininfo()) do
                            if win.quickfix == 1 then qf_exists = true end
                        end
                        if qf_exists then
                            vim.cmd('cclose')
                        else
                            vim.diagnostic.setqflist({ open = true })
                        end
                    end, opts)
                end,
            })
        end
    }
})
