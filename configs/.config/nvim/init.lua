-----------------------------------------------------------
-- Bootstrap lazy.nvim
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

if not uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
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

-----------------------------------------------------------
-- Basic settings
-----------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 必要なら昔の設定も流用
vim.cmd("source ~/.vimrc")

-----------------------------------------------------------
-- Plugins (lazy.nvim)
-----------------------------------------------------------
require("lazy").setup({
  spec = {
    -------------------------------------------------------
    -- mason: LSP 等のインストーラ
    -------------------------------------------------------
    {
      "mason-org/mason.nvim",
      opts = {}, -- README 推奨の素の設定で十分 
    },

    -------------------------------------------------------
    -- mason-lspconfig: LSP の自動インストール & 自動有効化
    -------------------------------------------------------
    {
      "mason-org/mason-lspconfig.nvim",
      dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
      opts = {
        -- よく使う LSP を自動インストール
        ensure_installed = {
          "clangd",
          "basedpyright",
          "rust_analyzer",
        },
        -- automatic_enable はデフォルト true:
        -- インストール済みサーバを vim.lsp.enable() で自動起動してくれる 
      },
    },

    -------------------------------------------------------
    -- nvim-lspconfig: サーバごとのデフォルト設定 + vim.lsp.config 連携
    -------------------------------------------------------
    {
      "neovim/nvim-lspconfig",
      -- cmp_nvim_lsp を先にロードして capabilities を作る
      dependencies = { "hrsh7th/cmp-nvim-lsp" },
      config = function()
        -- LSP completion capabilities (nvim-cmp 連携)
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        ---------------------------------------------------
        -- C / C++: clangd
        ---------------------------------------------------
        vim.lsp.config("clangd", {
          cmd = { "clangd", "--background-index", "--clang-tidy", "--inlay-hints" },
          filetypes = { "c", "cpp", "objc", "objcpp" },
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

        ---------------------------------------------------
        -- Rust: mason 管理の rust_analyzer をそのまま利用
        -- （特別な設定を足さず capabilities だけ乗せる）
        ---------------------------------------------------
        vim.lsp.config("rust_analyzer", {
          capabilities = capabilities,
          -- 必要になったら settings をここに追加
        })

        ---------------------------------------------------
        -- Python: pyright + プロジェクト直下 .venv の自動使用
        ---------------------------------------------------
        -- basedpyright/pyright のドキュメントでは、
        -- .venv がプロジェクト root にある場合にその環境を
        -- pythonPath として使えることが説明されています。
        vim.lsp.config("basedpyright", {
          capabilities = capabilities,
          settings = {
            python = {
              -- pythonPath は on_new_config で上書き
            },
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              autoImportCompletions = true,
            },
          },
          -- プロジェクト root ごとに .venv を検出して pythonPath に設定
          on_new_config = function(new_config, new_root_dir)
            local root = new_root_dir or vim.fn.getcwd()

            -- OS 判定して venv 内の python を決める
            local python_path
            if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
              python_path = root .. "\\.venv\\Scripts\\python.exe"
            else
              python_path = root .. "/.venv/bin/python"
            end

            if uv.fs_stat(python_path) then
              new_config.settings = new_config.settings or {}
              new_config.settings.python = new_config.settings.python or {}
              -- Qiita 記事の例の通り pythonPath を設定 
              new_config.settings.python.pythonPath = python_path
            end
          end,
        })

        ---------------------------------------------------
        -- MLIR: mlir_lsp_server（これは mason ではなく自前インストール想定）
        ---------------------------------------------------
        vim.lsp.config("mlir_lsp_server", {
          capabilities = capabilities,
          -- cmd や filetypes は nvim-lspconfig 側のデフォルトを使用
        })

        -- mlir_lsp_server は mason 管理ではないので自前で enable
        vim.lsp.enable("mlir_lsp_server")

        ---------------------------------------------------
        -- 共通 LSP キーマップ & Inlay Hints
        ---------------------------------------------------
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then
              return
            end

            local function buf_map(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, {
                buffer = bufnr,
                silent = true,
                desc = desc,
              })
            end

            -- コードアクション
            buf_map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP Code Action")
            -- 定義ジャンプ
            buf_map("n", "gD", vim.lsp.buf.definition, "Go to definition")
            -- リネーム
            buf_map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
            -- 行単位診断
            buf_map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")

            -- Inlay Hints (0.10+ の API)
            if client.server_capabilities.inlayHintProvider then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) -- 
            end
          end,
        })
      end,
    },

    -------------------------------------------------------
    -- nvim-cmp: 補完
    -------------------------------------------------------
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
            -- シンプルに vim.snippet があれば使う
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
    },
  },

  ---------------------------------------------------------
  -- lazy.nvim 全体のオプション
  ---------------------------------------------------------
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true }, -- プラグイン更新チェック
})

-----------------------------------------------------------
-- Colorscheme
-----------------------------------------------------------
vim.cmd("colorscheme habamax")

