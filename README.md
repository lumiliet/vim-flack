# vim-flack

Simple file explorer. Displays all files in the folder and all subfolders. Makes it easy to navigate coding projects because all files in the project are visible at once.

Requires `The Silver Searcher` to be installed on the system.

`:Flack` will open the explorer in project root if found, or current folder. Looks for a git repo for project root.
Use `enter` and `backspace` to navigate.

Open specific folder by using `:e <folder>`. For example `:e %:h` to open an explorer in the directory of the current file.

