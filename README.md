# Emacs settings

Settings forked from magnars/.emacs.d

## Setup

To grab all the dependencies:

    git clone --recursive git://github.com:jamesthompson/.emacs.d.git

The first time you start emacs, it will install some additional packages
that are best handled by the package manager.

## Install emacs on mac

    brew install emacs
    brew services start emacs

I removed the stock emacs version from Mac OS X 10.9 in /usr/bin

I manually installed Emacs cocoa binary into /Applications.

## Idiosyncrasies

 * Meta key is bound to command on a Mac.

 * Key bindings are listed in settings/key-bindings.el

 * You quit emacs with `C-x r q`, mnemonic *Really Quit*.

 * Find file in project with `C-x o`, in dir with `C-x C-f`, recent with `C-x f`

 * Help is bound to `F1`. `C-h` is rebound to backspace, like in the shell.

 * Autocomplete with `C-c e`

 * Expand-region is bound to `C-'`

 * Undo with `C-_` or `C-/` and redo with `M-_`. Watch the undo-tree with `C-x u`

 * Quickly jump anywhere in the buffer with `M-g` then the starting letter of a word. Press the letter highlighted to go there.

 * Indent and clean up white space in the entire buffer with `C-c n`

## Help

* `C      ` Shorthand for the ctrl-key
* `M      ` Shorthand for the meta-key (bound to cmd on my mac settings)
* `S      ` Shorthand for the shift-key

### Files

* `C-x C-f` Open a file. Starts in the current directory
* `C-x f  ` Open a recently visited file
* `C-x o  ` Open a file in the current project (based on .git ++)
* `C-x C-s` Save this file
* `C-x C-w` Save as ...
* `C-x C-j` Jump to this files' current directory
* `C-x b  ` Switch to another open file (buffer)
* `C-x C-b` List all open files (buffers)

### Cut copy and paste

* `C-space` Start marking stuff. C-g to cancel. Navigate however you desire to expand the region, you don't have to press anything to close it.
* `C-w    ` Cut (aka kill)
* `C-k    ` Cut till end of line
* `M-w    ` Copy
* `C-y    ` Paste (aka yank)
* `M-y    ` Cycle last paste through previous kills
* `C-x C-y` Choose what to paste from previous kills

### General

* `C-g    ` Quit out of whatever mess you've gotten yourself into
* `M-x    ` Run a command by name
* `C-.    ` Autocomplete
* `C-_    ` Undo
* `M-_    ` Redo
* `C-x u  ` Show the undo-tree
* `C-x m  ` Open magit. It's a magical git interface for emacs

### Navigation

* `C-arrow` Move past words/paragraphs
* `C-a    ` Go to start of line
* `C-e    ` Go to end of line
* `M-g M-g` Go to line number
* `C-x C-i` Go to symbol
* `C-s    ` Search forward. Press `C-s` again to go further.
* `C-r    ` Search backward. Press `C-r` again to go further.

### Window management

* `C-x 0  ` Close this window
* `C-x 1  ` Close other windows
* `C-x 2  ` Split window horizontally
* `C-x 3  ` Split window vertically
* `S-arrow` Jump to window to the left/right/up/down

### Help

* `F1 t   ` Basic tutorial
* `F1 k   ` Help for a keybinding
* `F1 r   ` Emacs' extensive documentation

### Magit (Git wrapper)

* `C-x m`. `s` to stage, `c` to commit. `C-c C-c` to finish commit msg buffer. `P u` to push upstream.

