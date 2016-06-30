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

fun! s:Insert(result)
    call s:Delete('%')
    call append('0', a:result)
    call s:Delete('$')
    normal gg
endf

fun! s:Delete(range)
    exec "silent " . a:range . "delete _"
endf

fun! s:Find(path)
    let defaultIgnored = ['/\.', 'node_modules/', 'vendor/']
    let ignoredFolders = s:GetIgnoredFolders(a:path) + defaultIgnored
    let grepExlude = join(ignoredFolders, '\|')
    if strlen(grepExlude) == 0
        let command = "find " . a:path
    else
        let command = "find " . a:path . " | grep -v '" . grepExlude . "'"
    endif

    let resultOneLIne = system(command)
    return split(resultOneLIne)
endf

fun! s:InsertFind(path)
    let files = s:Find(a:path)
    let shortFiles = s:ShortenFiles(files, a:path)
    let filteredFiles = filter(shortFiles, "strlen(v:val) && match(v:val, '^\\.') == -1")
    call s:Insert(filteredFiles)
endf

fun! s:ShortenFiles(files, path)
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

fun! FlackEditFileUnderCursor()
    let line = getline('.')
    let path = b:explorerPath . line
    if isdirectory(path)
        call s:Explorer(path)
    else
        exec "e " . path
    endif
endf

fun! FlackUpOneDirectory()
    let upped = substitute(b:explorerPath, '[^/]*/$', '', '')
    call s:Explorer(upped)
endf

fun! s:ExploreIfDirectory(path)
    if isdirectory(a:path)
        augroup FileExplorer
            autocmd!
        augroup END

        call s:Explorer(a:path)
    endif
endf


fun! s:Explorer(path)
    if !exists('b:isFlack') || strlen(a:path) == 0
        echo "new flack"
        :enew
        let b:isFlack = 1
    else
        echo "same flack"
    endif


    let safePath = substitute(a:path, '\([^/]$\)', '\1/', '')

    :set buftype=nofile

    let projectPath = s:FindProjectPath(fnamemodify(getcwd(), ':p'))
    let b:explorerPath = safePath

    if strlen(a:path) == 0
        let b:explorerPath = projectPath
    endif

    nnore <silent> <buffer> <CR> :call FlackEditFileUnderCursor()<CR>
    nnore <silent> <buffer> <BS> :call FlackUpOneDirectory()<CR>
    call s:InsertFind(b:explorerPath)

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


fun! s:Init()
    augroup flack
        autocmd BufEnter,VimEnter * call s:ExploreIfDirectory(expand('<amatch>'))
    augroup END

    com! Flack :call s:Explorer("")
endf

if !exists('s:ranOnce')
    let s:ranOnce = 1
    call s:Init()
endif
