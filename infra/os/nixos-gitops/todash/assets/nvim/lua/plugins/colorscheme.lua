-- common-lazyvim/.config/nvim/lua/plugins/colorscheme.lua
return {
  -- Add / configure Catppuccin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        telescope = { enabled = true },
        notify = true,
        mini = true,
        -- add more integrations as you enable those plugins
      },
    },
  },

  -- Tell LazyVim to use Catppuccin as the colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}

