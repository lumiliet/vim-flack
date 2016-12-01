fun! s:FindProjectPath(path)
    let path = finddir('.git', a:path . ';~/')
    if len(path)
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
    let command = "ag -g '' " . a:path
    return s:ShortenFiles(split(system(command)), a:path)
endf

fun! s:GetDirectories(files)
    let files = copy(a:files)
    if !len(files)
        return []
    endif

    call filter(files, "len(matchlist(v:val, '/.*$'))")
    call map(files, "substitute(v:val, '/[^/]*$', '', '')")
    return files + s:GetDirectories(files)
endf

fun! s:InsertFind(path)
    let files = s:Find(a:path)
    let directories = s:GetDirectories(files)
    let filesAndDirectories = uniq(sort(files + directories))

    call s:Insert(filesAndDirectories)
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
    let projectPath = s:FindProjectPath(expand('%:p'))

    if !exists('b:flackBufferNumber') || strlen(a:path) == 0
        :enew
        :set buftype=nowrite
        nnore <silent> <buffer> <CR> :call FlackEditFileUnderCursor()<CR>
        nnore <silent> <buffer> <BS> :call FlackUpOneDirectory()<CR>

        let b:flackBufferNumber = bufnr('%')
    endif

    let safePath = substitute(a:path, '\([^/]$\)', '\1/', '')


    if strlen(a:path) == 0
        let b:explorerPath = projectPath
    else
        let b:explorerPath = safePath
    endif

    call s:InsertFind(b:explorerPath)

endf

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

