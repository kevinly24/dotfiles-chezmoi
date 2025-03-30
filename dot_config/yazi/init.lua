require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

require("bunny"):setup({
  hops = {
    { key = "h",          path = "~", desc = "Home"},
    { key = "i",          path = "~/Library/Mobile Documents/com~apple~CloudDocs", desc = "iCloud"},
    { key = "c",          path = "~/.config",      desc = "Config files" },
  },
  desc_strategy = "path", -- If desc isn't present, use "path" or "filename", default is "path"
  notify = false, -- Notify after hopping, default is false
  fuzzy_cmd = "fzf", -- Fuzzy searching command, default is "fzf"
})
