# dap-hot-config.nvim

Adds commands to Neovim that let you configure [nvim-dap](https://github.com/mfussenegger/nvim-dap) without adding launch.json files to your project or editing your global DAP configurations.

To use, just install this plugin however you do, and run `require'dap-hot-config'` however you do

TODO: Make proper documentation instead of putting all this in README.md

## Commands

### :Argv

List or modify the arguments that will be passed to your program when debugging. When successful, prints out the table of arguments. The Neovim command can look like any of the following:

| Argv       | only prints the args    |
|:------------- |:-------------- |
| `Argv pop`                | removes the last item in args     |
| `Argv clear`              | sets args to an empty table    |
| `Argv <index>`            | sets args[`index`] to an empty string     |
| `Argv <index> <value>`    | sets args[`index`] to `value`. `value` can start with whitespace, if you just put the whitespace after the separating space between `index` and `value`.     |

For those last two uses, the index supplied cannot be greater than any index that was not yet supplied.

### :Main

I often want to debug a module that doesn't do anything on its own. To do that, you need a separate program that runs tests on the module so that you can debug the module by starting a debug session on the tester. This command is a solution to keep you from having to flip back and forth between the tester that you want to launch, and the module that has all the bugs.

This command modifies the "program" entry of your configuration. Did you know that this entry can be either a string or a function that returns a string? If you want to use the Main command, then the "program" entry must be the latter. Here is an example function:

program = function() return vim.fn.expand('%:p') end

This works the same as setting `program = '${file}'`, except that this way you can use Main. When you call Main, dap-hot-config.nvim will execute your function and store the output as the value for "program" in your configuration. Now that the value for "program" is a string, and not a format string, the same program will be run for debugging every time. Specifically, the buffer you had open when you called Main.

The default function is not forgotten, though. Therefore, you can still call Main on another buffer.

### :Unmain

Undoes the effect of Main. While Main turns the value of "program" to a string, Unmain turns it back into the function you set manually.

## Limitations

Currently, dap-hot-config.nvim only expects one configuration per filetype. If you have two Python configurations, for example, then Argv/Main/Unmain will only modify the first. The workaround is to order your configurations so that the one you want to edit on-the-fly the most is first. In other words, make it the "primary configuration".

Also, you can't use Main to run a program that uses a different filetype. The exception is if multiple filetypes have the exact same table as their primary configuration.

Your options for Main and Argv do not persist after Neovim is closed or the plugin is reloaded.

Using commands to configure your debug launch is very cool, but this plugin only lets you modify the arguments given and the program to be launched. Perhaps this plugin could also modify the environment variables visible to the debuggee or other cool shit.
