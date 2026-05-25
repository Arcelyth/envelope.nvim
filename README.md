# Envelope

A neovim plugin that send neovim's runtime informations via UDP to external applications. <br>
**Support**: 
- Diagnostic messages
- Treesitter node type.

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
    -- open for sending current treesitter node type
	treesitter = true,
	treesitter_color = { 124, 186, 196 },
    -- open for sending diagnostic messages 
	diag = true,
	use = true,
    debounce_time = 50,
})
```

## Commands

`EnvelopeSwitch`: Enable/Disable all the functions
