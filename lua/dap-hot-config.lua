-- For internal use, get the configuration that should be edited based on that filetype. If DAP has multiple
-- configurations associated with that filetype, just get the first one.
-- If the configuration is missing, print a message and return nil.
-- TODO: maybe this plugin could modify all configurations associated with the filetype, instead of just the first one.
local function get_config(filetype)
  -- Get the appropriate table of DAP configurations using the filetype of the current buffer, and make sure it's valid
  local config_table = require'dap'.configurations[filetype]
  if config_table == nil then
    print(filetype .. " not found in require'dap'.configurations")
    return nil
  end

  local config = config_table[1]
  if config == nil then
    print("No configuration found in require'dap'.configurations." .. filetype)
  end
  return config
end

-- Similar to GetConfig, but also checks that the configuration has a _default_program field, which is automatically
-- added to all (Un)Main-able configurations in Setup
local function get_config_with_default_program(filetype)
  local config = get_config(filetype)
  if config == nil then return nil end

  if config._default_program == nil then
    print("require'dap'.configurations." .. filetype .. "[1].program is not set to a function by default")
    print("Example function that returns the path to the file being currently edited:")
    print("function()\n  return vim.fn.expand('%p:)\nend")
    return nil
  end

  return config
end

-- Edit the `program` field of the appropriate dap configuration
-- If the default value of this field was appropriately set to a function, then run the function and modify the field
-- to hold a string, the return value.
local function main()
  local filetype = vim.bo.filetype
  local config = get_config_with_default_program(filetype)
  if config == nil then return end

  config.program = config._default_program()
  print("require'dap'.configurations'." .. filetype .. "[1].program = " .. config.program)
end

-- Edit the `program` field of the appropriate dap configuration
-- If the default value of this field was appropriately set to a function, then set the field back to its default value
function Unmain()
  local filetype = vim.bo.filetype
  local config = get_config_with_default_program(filetype)
  if config == nil then return end

  config.program = config._default_program
  print("require'dap'.configurations'." .. filetype .. "[1].program reset")
  return true
end

-- Undo the function Main
local function unmain()
  local filetype = vim.bo.filetype
  local config = get_config(filetype)
  if config == nil then return end

  if config._default_program == nil then
    print("require'dap'.configurations." .. filetype .. "[1].program is not a function")
    print("Example function that returns the path to the file being currently edited:")
    print("function()\n  return vim.fn.expand('%p:)\nend")
    return
  end

  config.program = config._default_program
  print("require'dap'.configurations'." .. filetype .. "[1].program = " .. config.program)
end

-- Takes in an argument table from the nvim_create_user_command API. Accordingly adjusts the args table of the DAP
-- configuration corresponding to the filetype of the current buffer. When successful, prints out the args table.
-- The Vim command can look like any of the following:
-- Argv .................. only prints the args
-- Argv pop .............. removes the last item in args
-- Argv clear ............ sets args to an empty table
-- Argv <index> .......... sets args[index] to an empty string
-- Argv <index> <value> .. sets args[index] to value. value can start with whitespace, just put the whitespace after the
--                           separating space between <index> and <value>
local function argv(my)
  local filetype = vim.bo.filetype
  local config = get_config(filetype)
  if config == nil then return end

  -- If there is no args table, make an empty one before doing anything!
  config.args = config.args or {}

  -- Helper function to print the current args table
  local function print_args()
    print("require'dap'.configurations." .. filetype .. "[1].args")
    for k, v in ipairs(config.args) do
      print(tostring(k) .. "=" .. v) -- Prints "k=v"
    end
  end

  -- If the user passed no arguments, simply print out all configured arguments
  if my.args == '' then
    print_args()
    return
  end

  -- Check if the user wants the 'pop' or 'clear' subcommands
  if my.args == 'pop' then
    config.args[#config.args] = nil -- Remove the last item in the args table
    print_args()
    return
  elseif my.args == 'clear' then
    config.args = {} -- Remove every item in the args table
    print_args()
    return
  end

  -- No subcommand given, so the user must want to modify the args table at a specific index
  -- Get the index of the argument that the user wants to modify, and make sure it is valid
  local index = tonumber(my.fargs[1])
  if index == nil or index % 1 ~= 0 then
    print(my.fargs[1] .. " is not a valid index or 'pop' or 'clear'")
    return
  elseif index <= 0 or index > #config.args + 1 then
    print(tostring(index) .. " is out of bounds for the current args table")
    return
  end

  -- Get the value that the user wants to put at that index, which is an empty string if nothing is given
  local value = my.args:sub(string.len(my.fargs[1]) + 2)

  -- Apply the configuration and print out the args
  config.args[index] = value
  print_args()
end

local function setup()
  -- Sneakily store the default value for `program` in each primary configuration as `_default_program`
  -- By primary configuration, I mean the first configuration in the table associated with any filetype.
  for _, config_table in require'dap'.configurations do
    local config = config_table[1]
    if config and type(config.program) == 'function' then
      config._default_program = config.program
    end
  end

  -- Set user commands
  vim.api.nvim_create_user_command('Main', main, {})
  vim.api.nvim_create_user_command('Unmain', unmain, {})
  vim.api.nvim_create_user_command('Argv', argv, { nargs = '*' })
end

return {
  setup = setup
}
