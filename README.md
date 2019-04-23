# vim-tidal #

A Vim plugin for [TidalCycles](http://tidal.lurk.org/), the language for live
coding musical patterns written in Haskell.

This plugin uses the terminal feature of Vim 8.

[![asciicast](https://asciinema.org/a/224891.svg)](https://asciinema.org/a/224891)

## Getting Started ##

   When inside Vim, run the command `:TidalStart`.
   A new pane should appear below with Tidal running.


## Install ##

I recommend using a Vim plugin manager like
[Plug](https://github.com/junegunn/vim-plug).  Check the link for instructions
on installing and configuring.  If you don't want a plugin manager, you can
also download the latest release
[here](https://github.com/tidalcycles/vim-tidal/releases) and extract the
contents on your Vim directory (usually `~/.vim/`).

For example, with Plug you need to:

  * Edit your `.vimrc` file and add these lines:

```vim
Plug 'flupe/vim-tidal'
```

  * Restart Vim and execute `:PlugInstall` to automatically download and
    install the plugins.


### Commands

These are some of the commands that can be run from Vim command line:

* `:<range>TidalSend`: Send a `[range]` of lines. If no range is provided the
  current line is sent.

* `:TidalSend1 {text}`: Send a single line of text specified on the command
  line.

* `:TidalHush`: Silences all streams by sending `hush`.


### Default bindings

Using one of these key bindings you can send lines to Tidal:

* `<c-e>` (Control+E), `<localleader><localleader>`: Send current inner paragraph.
* `<localleader>s`: Send current line or current visually selected block.

`<c-e>` can be called on either Normal, Visual, Select or Insert mode, so it is
probably easier to type than `<localleader><localleader>` or `<localleader>s`.

There are other bindings to control Tidal like:

* `<localleader>h`, `<c-h>`: Call `:TidalHush`

#### About `<localleader>`

The `<leader>` key is a special key used to perform commands with a sequence of
keys.  The `<localleader>` key behaves as the `<leader>` key, but is *local* to
a buffer.  In particular, the above bindings only work in buffers with the
"tidal" file type set, e.g. files whose file type is `.tidal`

By default, there is no `<localleader>` set.  To define one, e.g. for use with
a comma (`,`), write this on your `.vimrc` file:

```vim
let maplocalleader=","
```

Reload your configuration (or restart Vim), and after typing `,ss` on a few
lines of code, you should see those being copied onto the Tidal interpreter on
the lower pane.


## Configure ##

### GHCI

By default, `vim-tidal` uses the globally installed GHCI to launch the REPL.
If you have installed Tidal through Stack (`stack install tidal`),
you can specify another command to use with `g:tidal_ghci`.

For example, if one installed Tidal with Stack, they would use:

```vim
let g:tidal_ghci = "stack exec ghci --"
```


### Default bindings ###

By default, there are two normal keybindings and one for visual blocks using
your `<localleader>` key.  If you don't have one defined, set it on your
`.vimrc` script with `let maplocalleader=","`, for example.

If you don't like some of the bindings or want to change them, add this line to
disable them:

```vim
let g:tidal_no_mappings = 1
```

See section Mappings on [ftplugin/tidal.vim](ftplugin/tidal.vim) and copy the
bindings you like to your `.vimrc` file and modify them.


### Miscelaneous ###

When sending a paragraph or a single line, vim-tidal will "flash" the selection
for some milliseconds.  By default duration is set to 150ms, but you can modify
it by setting the `g:tidal_flash_duration` variable.


## License

Refer to the [LICENSE](LICENSE) file
