-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
-- Themes I like: Ashes (light) (terminal.sexy), Bluloco Zsh Light (Gogh), Breath Light (Gogh)
config.color_scheme = 'Catppuccin Latte'
config.font = wezterm.font("FiraCode Nerd Font", {weight="Medium", stretch="Normal", style="Normal"})
config.font_size = 12.0
config.window_background_opacity = 1
config.window_decorations = "RESIZE"
config.audible_bell = "Disabled"

config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = false
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 10,
  right = 10,
  top = 5,
  bottom = 0,
}

-- and finally, return the configuration to wezterm
return config
