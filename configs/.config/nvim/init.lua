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

-- ここはそのまま（ただし、古い LSP 設定が .vimrc にあると競合する可能性はあります）
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
        ensure_installed = {
          "clangd",
          "basedpyright",
          "rust_analyzer",
        },
        -- automatic_enable はデフォルト true:
        -- インストール済みサーバを vim.lsp.enable() で自動起動
        -- automatic_enable = true,
      },
    },

    -------------------------------------------------------
    -- nvim-lspconfig: サーバごとのデフォルト設定 + vim.lsp.config 連携
    -------------------------------------------------------
    {
      "neovim/nvim-lspconfig",
      dependencies = { "hrsh7th/cmp-nvim-lsp" },
      config = function()
        ---------------------------------------------------
        -- 共通 capabilities（nvim-cmp 連携）
        ---------------------------------------------------
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- すべての LSP 設定にマージされる共通設定
        vim.lsp.config("*", {
          capabilities = capabilities,
        })

        ---------------------------------------------------
        -- C / C++: clangd
        ---------------------------------------------------
        vim.lsp.config("clangd", {
          cmd = { "clangd", "--background-index", "--clang-tidy", "--inlay-hints" },
          filetypes = { "c", "cpp", "objc", "objcpp" },
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
        -- Rust: rust_analyzer
        ---------------------------------------------------
        vim.lsp.config("rust_analyzer", {
          -- 必要になったら settings をここに追加
          -- settings = {
          --   ["rust-analyzer"] = { ... },
          -- },
        })

        ---------------------------------------------------
        -- Python: basedpyright + プロジェクト直下 .venv の自動使用
        ---------------------------------------------------
        vim.lsp.config("basedpyright", {
          -- basedpyright ドキュメント準拠の settings 構造
          settings = {
            basedpyright = {
              analysis = {
                -- 元の pyright 用設定を basedpyright.analysis.* に移行
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
                typeCheckingMode = "standard",
                -- 必要なら：
                diagnosticMode = "workspace", -- 大規模プロジェクトで全体を診断したい場合
              },
            },
            -- python.* は pythonPath / venvPath だけ有効
            python = {
              -- pythonPath は before_init で上書き
            },
          },

          -- -- .venv をプロジェクト階層から探して python.pythonPath に設定
          -- -- （vim.lsp.config での on_new_config は扱いが微妙なので before_init で行う）
          -- before_init = function(_, config)
          --   -- 現在のバッファから上方向に .venv ディレクトリを探す
          --   local bufname = vim.api.nvim_buf_get_name(0)
          --   if bufname == "" then
          --     return
          --   end

          --   local start_dir = vim.fs.dirname(bufname)
          --   local venv_dirs = vim.fs.find(".venv", {
          --     path = start_dir,
          --     upward = true,
          --     type = "directory",
          --   })
          --   local venv_dir = venv_dirs[1]
          --   if not venv_dir then
          --     return
          --   end

          --   local python_path
          --   if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
          --     python_path = venv_dir .. "\\Scripts\\python.exe"
          --   else
          --     python_path = venv_dir .. "/bin/python"
          --   end

          --   if not uv.fs_stat(python_path) then
          --     return
          --   end

          --   config.settings = config.settings or {}
          --   config.settings.python = config.settings.python or {}
          --   config.settings.python.pythonPath = python_path
          -- end,
        })

        ---------------------------------------------------
        -- MLIR: mlir_lsp_server
        ---------------------------------------------------
        if vim.fn.executable("mlir-lsp-server") == 1 then
          vim.lsp.config("mlir_lsp_server", {
            -- capabilities は "*" 側で共通設定済みなら省略可
            -- 何か個別の設定を足したいならここに書く
            -- settings = { },
          })

          vim.lsp.enable("mlir_lsp_server")
        else
          -- 静かに無視したいならこの print は消してOK
          vim.notify("mlir-lsp-server not found in PATH, skipping mlir_lsp_server LSP", vim.log.levels.DEBUG)
        end

        ---------------------------------------------------
        -- TableGen: tblgen_lsp_server
        ---------------------------------------------------
        if vim.fn.executable("tblgen-lsp-server") == 1 then
          vim.lsp.config("tblgen_lsp_server", {
          })

          vim.lsp.enable("tblgen_lsp_server")
        else
          -- 静かに無視したいならこの print は消してOK
          vim.notify("tblgen-lsp-server not found in PATH, skipping tblgen_lsp_server LSP", vim.log.levels.DEBUG)
        end

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

            -- Inlay Hints
            if client.server_capabilities.inlayHintProvider then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
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
    -------------------------------------------------------
    -- LSP progress 表示 (任意だけどオススメ)
    -------------------------------------------------------
    {
      "j-hui/fidget.nvim",
      opts = {
        -- とりあえずデフォルトでOK
      },
    },

  },

  ---------------------------------------------------------
  -- lazy.nvim 全体のオプション
  ---------------------------------------------------------
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true }, -- プラグイン更新チェック
})
vim.lsp.set_log_level("debug")

-----------------------------------------------------------
-- Colorscheme
-----------------------------------------------------------
vim.cmd("colorscheme habamax")

