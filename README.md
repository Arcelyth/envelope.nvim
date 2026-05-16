# Envelope

A neovim plugin that send neovim's diagnostic messages via UDP to external applications. <br>

## Installation

### Lazy: 
```lua
{ "Arcelyth/envelope.nvim" }
```

## Configuration

```
-- default config
require("envelope").setup({
    host = "127.0.0.1",
    port = 10824,
	warning_color = { 227, 212, 98 },
	error_color = { 224, 93, 70 },
	info_color = { 79, 201, 194 },
	hint_color = { 79, 201, 148 },
    id = "envelope.nvim",
    use = true,
})
```

## Commands

`EnvelopeSwitch`: Enable/Disable all the functions
