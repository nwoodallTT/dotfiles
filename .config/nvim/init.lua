-- ============================================================================
-- Options
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 8
opt.ignorecase = true
opt.smartcase = true
opt.undofile = true
opt.splitright = true
opt.splitbelow = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.updatetime = 250

-- Reload buffers when an external process (e.g. the agent) rewrites the file
-- on disk. autoread alone is passive; checktime forces the poll on focus/idle.
opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  callback = function()
    vim.notify("Buffer reloaded — changed on disk", vim.log.levels.WARN)
  end,
})

-- ============================================================================
-- Bootstrap lazy.nvim
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- Plugins
-- ============================================================================
require("lazy").setup({
  { "ellisonleao/gruvbox.nvim", priority = 1000, config = function()
      vim.cmd.colorscheme("gruvbox")
    end },

  -- File browser
  { "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 36 },
        update_focused_file = { enable = true },
        filters = { custom = { "^.git$" } },
      })
    end },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local t = require("telescope")
      t.setup({
        defaults = {
          -- A 1.4T tree includes the build output; never grep into it.
          file_ignore_patterns = { "%.git/", "build/", "build_Release/", "%.o$", "%.a$" },
        },
      })
      t.load_extension("fzf")
    end },

  -- Git: show the agent's edits as hunks in the sign column
  { "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({ current_line_blame = false })
    end },

  -- Syntax / structure
  { "nvim-treesitter/nvim-treesitter", branch = "master", build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "cpp", "python", "lua", "bash", "cmake", "yaml", "json", "markdown" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(a) require("luasnip").lsp_expand(a.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = { { name = "nvim_lsp" }, { name = "luasnip" }, { name = "buffer" }, { name = "path" } },
      })
    end },
}, {
  ui = { border = "rounded" },
})

-- ============================================================================
-- LSP servers
-- ============================================================================
-- nvim-lspconfig ships the base definitions (filetypes, root markers, default
-- cmd) under lsp/; vim.lsp.config layers our overrides, vim.lsp.enable starts.
local caps = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", { capabilities = caps })

-- clangd reads build/compile_commands.json; header-insertion off avoids noise
-- in a generated-heavy tree, background-index keeps the rest of the repo warm.
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--compile-commands-dir=build",
    "--background-index",
    "--header-insertion=never",
    "--clang-tidy=false",
    "-j=8",
  },
})

vim.lsp.enable({ "clangd", "pyright" })

-- ============================================================================
-- Keymaps
-- ============================================================================
local map = vim.keymap.set
local tb = require("telescope.builtin")

-- Find / search
map("n", "<leader>ff", tb.find_files, { desc = "Find files" })
map("n", "<leader>fg", tb.live_grep, { desc = "Grep (ripgrep)" })
map("n", "<leader>fb", tb.buffers, { desc = "Buffers" })
map("n", "<leader>fh", tb.help_tags, { desc = "Help" })
map("n", "<leader>fs", tb.lsp_document_symbols, { desc = "Document symbols" })
map("n", "<leader>fw", tb.grep_string, { desc = "Grep word under cursor" })

-- File tree
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
map("n", "<leader>o", "<cmd>NvimTreeFindFile<cr>", { desc = "Reveal file in tree" })

-- Git / seeing the agent's edits
map("n", "]c", function() require("gitsigns").nav_hunk("next") end, { desc = "Next change" })
map("n", "[c", function() require("gitsigns").nav_hunk("prev") end, { desc = "Prev change" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview hunk" })
map("n", "<leader>gd", "<cmd>Gitsigns diffthis<cr>", { desc = "Diff this file vs HEAD" })
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })

-- LSP (active once a server attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local o = { buffer = ev.buf }
    map("n", "gd", tb.lsp_definitions, vim.tbl_extend("force", o, { desc = "Go to definition" }))
    map("n", "gr", tb.lsp_references, vim.tbl_extend("force", o, { desc = "References" }))
    map("n", "gi", tb.lsp_implementations, vim.tbl_extend("force", o, { desc = "Implementations" }))
    map("n", "K", vim.lsp.buf.hover, o)
    map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", o, { desc = "Rename" }))
    map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", o, { desc = "Code action" }))
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, o)
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, o)
  end,
})

-- Misc
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<leader>R", "<cmd>checktime<cr>", { desc = "Reload changed files" })
