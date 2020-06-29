# popsikey

[![This project is considered experimental](https://img.shields.io/badge/status-experimental-critical.svg)](https://benknoble.github.io/status/experimental/)

Vim plugin that turns prefixed mappings into pop-up menus.

## What is it?

If you have lots of vim mappings that relate to the same subject, you may have
"namespaced" them by using a prefix.

As an example, suppose all of your git mappings start with `<leader>g`:

- `<leader>gg` is `:Gstatus`
- `<leader>gc` is `:Gcommit`

popsikey provides an interface to automatically turn those mappings into a popup
menu when it's supported. With our example mappings, you would create this by
doing

    call popsikey#register('<leader>g', [
            \ #{key: 'g', info: 'status', action: ":Gstatus\<CR>", flags: 'n'},
            \ #{key: 'c', info: 'commit', action: ":Gcommit\<CR>", flags: 'n'},
            \ ],
            \ {})

So, `<leader>g` pops up the menu of git mappings, which is a list of map keys
and descriptions. You navigate with the usual keys (`j`, `k`, `q`, `<Esc>`,
`<Enter>`).  But your mappings work--so  pressing `g` inside the
popup will trigger `:Gstatus` as a shortcut to navigating the menu.

And, if your vim doesn't support popups yet, you'll get regular old mappings:

    nnoremap <leader>gg :Gstatus<CR>
    nnoremap <leader>gc :Gcommit<CR>

That means the experience is seamless everywhere.

**Note** only normal-mode mappings are currently supported.

## How do I use it?

Install it, and then call `popsikey#register` (note that I used `const` and `->`
methods liberally in the code, so your vim will need to support those).

The `popsikey#register` function takes the following arguments:

- `prefix`: the mapping prefix, like `<leader>g`
- `maps`: a list of mapping dictionaries. Each must contain the following keys
  (strings):
  - `key`: the key on which to trigger the mapping (without the prefix)
  - `info`: a short description of the action for this mapping
  - `action`: the action to take (this will be fed to `feedkeys`, so you may
    need double-quotes and backslash-escapes on special characters like `<CR>`)
  - `flags`: a string of `feedkeys` flags. If `flags` would cause keys not be
    mapped by `feedkeys` and popups are unavailable, the created mappings are
    non-recursive. Otherwise, the mappings are recursive.
- `opts`: a dictionary of options to pass to `popup_create` (see `:help
  popup_create-arguments`). Merged with a default of
```vim
#{
        \ filter: 'popsikey#filter',
        \ callback: 'popsikey#callback',
        \ title: prefix,
        \ padding: [1,2,1,2],
        \ pos: 'topleft',
        \ line: 'cursor+1',
        \ col: 'cursor',
        \ }
```

Do not override `filter` or `callback`, or you will break the menu's
key-handlers.

This should be enough to get started with most setups. If you need more
customization, check out `:help popsikey`.

## What if I don't have prefixed mappings?

Then this probably isn't going to be a plugin or a solution you need--after the
first stroke of non-prefixed mapping, there's nothing left to "popup."

Most default keybindings are mnemonically named. I found that when creating my
own keybindings, however, I often namespaced related operations together by
using a second prefix under leader and left general operations as single keys
under my leader.
