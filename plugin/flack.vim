fun! s:FindProjectPath(path)
    let path = finddir('.git', a:path . ';~/')
    if len(path) && g:pathfinder_look_for_git
        let path = fnamemodify(path, ':h')
    else
        let path = fnamemodify(a:path, ':p')
    endif
    let path = fnamemodify(path, ':p')
    return path
endf

fun! Insert(result)
    call Delete('%')
    call append('0', a:result)
    call Delete('$')
    normal gg
endf

fun! Delete(range)
    exec "silent " . a:range . "delete _"
endf

fun! Find(path)

    let ignoredFolders = s:GetIgnoredFolders(a:path)
    let grepExlude = join(ignoredFolders, '\|')
    if strlen(grepExlude) == 0
        let command = "find " . a:path
    else
        let command = "find " . a:path . " | grep -v '" . grepExlude . "'"
    endif

    let resultOneLIne = system(command)
    return split(resultOneLIne)
endf

fun! InsertFind(path)
    let files = Find(a:path)
    let shortFiles = ShortenFiles(files, a:path)
    let filteredFiles = filter(shortFiles, "strlen(v:val) && match(v:val, '^\\.') == -1")
    call Insert(filteredFiles)
endf

fun! ShortenFiles(files, path)
    let list = []
    for file in a:files
        let substituted = substitute(file, a:path, '', '')
        let substituted = substitute(substituted, "^\/", '', '')
        call add(list, substituted)
    endfor
    return list
endf

fun! s:EditFile(path)
    exec "e " . a:path
endf

fun! EditFileUnderCursor()
    let line = getline('.')
    call s:EditFile(b:explorerPath . line)
endf

fun! s:ExploreIfDirectory(path)
    if isdirectory(a:path)
        augroup FileExplorer
            autocmd!
        augroup END

        let safePath = substitute(a:path, '\([^/]$\)', '\1/', '')
        echo safePath
        call Explorer(safePath)
    endif
endf

fun! Explorer(path)
    :set buftype=nofile

    let projectPath = s:FindProjectPath(fnamemodify(getcwd(), ':p'))
    let b:explorerPath = a:path
    if strlen(a:path) == 0
        let b:explorerPath = projectPath
    endif

    nnore <silent> <buffer> <CR> :call EditFileUnderCursor()<CR>
    call InsertFind(b:explorerPath)

endf

function! s:GetIgnoredFolders(path)
    let gitignore = a:path . '/.gitignore'
    let command = "cat " . gitignore . " | grep '/$'"
    let folders = []
    if filereadable(gitignore) && g:pathfinder_use_gitignore
        let folders = split(system(command))
    endif
    return folders
endfunction

augroup flack
    autocmd BufEnter,VimEnter * call s:ExploreIfDirectory(expand('<amatch>'))
augroup END
