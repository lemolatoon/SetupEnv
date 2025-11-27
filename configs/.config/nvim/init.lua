-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.cmd("source ~/.vimrc")

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- add your plugins here
		{
			"neovim/nvim-lspconfig",
			config = function()
				local lspconfig = require("lspconfig")
				-- Let LSP advertise nvim-cmp completion capabilities (incl. snippet support)
				local capabilities = require("cmp_nvim_lsp").default_capabilities(
					vim.lsp.protocol.make_client_capabilities()
				)
				lspconfig.clangd.setup({
					cmd = { "clangd", "--background-index", "--clang-tidy", "--inlay-hints" },
					filetypes = { "c", "cpp", "objc", "objcpp" },
					root_dir = function(fname)
						return require("lspconfig.util").root_pattern(
							"build/compile_commands.json",
							"compile_commands.json",
							"compile_flags.txt",
							".git"
						)(fname) or vim.loop.os_homedir()
					end,
					capabilities = capabilities,
					settings = {
						clangd = {
							inlayHints = {
								enable = true,
								parameterNames = true,
								deducedTypes = true,
							},
							fallbackFlags = { "-std=c++17" },
						},
					},
				})

				lspconfig.mlir_lsp_server.setup({ capabilities = capabilities })
				-- lspconfig.pyright.setup({})

				-- Use jedi-language-server with the project's .venv Python
				lspconfig.jedi_language_server.setup({
					cmd = { "jedi-language-server" },
					capabilities = capabilities,
					root_dir = function(fname)
						return require("lspconfig.util").root_pattern(
							".git",
							"pyproject.toml",
							"setup.cfg",
							"setup.py",
							"requirements.txt",
							".venv"
						)(fname) or vim.loop.os_homedir()
					end,
					init_options = {
						workspace = {
							-- default; updated per project in on_new_config
							environmentPath = vim.fn.getcwd() .. "/.venv",
						},
						completion = {
							-- Some clients need eager resolve to surface items; keep snippets off for simpler cmp setup
							disableSnippets = true,
							resolveEagerly = true,
						},
					},
					on_new_config = function(new_config, new_root_dir)
						local root = new_root_dir or vim.fn.getcwd()
						local venv = root .. "/.venv"
						local venv_python = venv .. "/bin/python"
						local venv_jls = venv .. "/bin/jedi-language-server"
						if vim.loop.fs_stat(venv_python) then
							-- jedi expects the venv root; it appends /bin/python internally
							new_config.init_options.workspace.environmentPath = venv
							if vim.loop.fs_stat(venv_jls) then
								new_config.cmd = { venv_jls }
							end
						elseif vim.env.VIRTUAL_ENV and vim.loop.fs_stat(vim.env.VIRTUAL_ENV .. "/bin/python") then
							new_config.init_options.workspace.environmentPath = vim.env.VIRTUAL_ENV
							if vim.loop.fs_stat(vim.env.VIRTUAL_ENV .. "/bin/jedi-language-server") then
								new_config.cmd = { vim.env.VIRTUAL_ENV .. "/bin/jedi-language-server" }
							end
						else
							-- fall back to system python; give its directory so jedi can resolve bin/python
							new_config.init_options.workspace.environmentPath = vim.fn.fnamemodify(vim.fn.exepath("python3"), ":h:h")
						end
					end,
				})
			end,
		},
		{
			"hrsh7th/nvim-cmp",
			dependencies = {
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-cmdline",
			},
			config = function()
				local cmp = require("cmp")
				vim.o.completeopt = "menu,menuone,noselect"
				cmp.setup({
					snippet = {
						-- Minimal snippet support so LSP items with snippets can expand
						expand = function(args)
							if vim.snippet then
								vim.snippet.expand(args.body)
							end
						end,
					},
					mapping = {
						["<Tab>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
						["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
						["<C-Space>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
					},
					sources = {
						{ name = "nvim_lsp" },
						{ name = "buffer" },
						{ name = "path" },
					},
					completion = {
						completeopt = "menu,menuone,noselect",
					},
				})
			end,
		}, -- lazy.nvim の spec テーブル内に以下を追加
		{
			"simrat39/rust-tools.nvim",
			dependencies = { "neovim/nvim-lspconfig" },
			config = function()
				local rt = require("rust-tools")

				rt.setup({
					server = {
						-- rust-analyzer の設定をここに書く
						cmd = { "rust-analyzer" },
						capabilities = require("cmp_nvim_lsp").default_capabilities(),
						settings = {
							["rust-analyzer"] = {
								cargo = { allFeatures = true },
								checkOnSave = { command = "clippy" },
								inlayHints = {
									lifetimeElisionHints = { enable = true, useParameterNames = true },
									bindingModeHints = { enable = true },
								},
							},
						},
					},
					tools = {
						-- inlay hints を自動的に有効化
						inlay_hints = { auto = true },
						-- hover actions をポップアップで表示
						hover_actions = { auto_focus = true },
					},
				})

				-- 任意：キー設定を上書きする場合
				vim.keymap.set("n", "<leader>rh", rt.hover_actions.hover_actions, { desc = "Rust Hover Actions" })
				vim.keymap.set(
					"n",
					"<leader>rc",
					rt.code_action_group.code_action_group,
					{ desc = "Rust Code Actions" }
				)
			end,
		},
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "habamax" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})

require("lspconfig").clangd.setup({
	cmd = { "clangd", "--background-index", "--clang-tidy", "--inlay-hints" },
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_dir = function(fname)
		return require("lspconfig.util").root_pattern(
			"build/compile_commands.json",
			"compile_commands.json",
			"compile_flags.txt",
			".git"
		)(fname) or vim.loop.os_homedir()
	end,
	capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
	settings = {
		clangd = {
			inlayHints = {
				enable = true,
				parameterNames = true,
				deducedTypes = true,
			},
			fallbackFlags = { "-std=c++17" },
		},
	},
})

vim.cmd("colorscheme habamax")
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		local buf_map = function(mode, lhs, rhs, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, lhs, rhs, opts)
		end
		-- クイックフィックス（コードアクション）のキーマッピング
		buf_map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP Code Action" })
		-- 定義ジャンプ用のキーバインド
		vim.keymap.set("n", "gD", vim.lsp.buf.definition, { desc = "Go to definition" })
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
		-- エラーメッセージ
		vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true)
		end
	end,
})
