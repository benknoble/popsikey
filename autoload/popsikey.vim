function popsikey#register(prefix, maps, opts) abort
  let g:popsikey = get(g:, 'popsikey', {})
  let l:extended_maps = deepcopy(a:maps)
        \ ->map({_, m -> extend(#{flags: 'n'}, m)})

  const l:id = s:get_id()
  let g:popsikey[l:id] = #{
        \ prefix: a:prefix,
        \ maps: l:extended_maps,
        \ opts: deepcopy(a:opts),
        \ keys: deepcopy(a:maps)->map({_, v -> v.key}),
        \ }

  " create mappings
  if has('popupwin')
    execute printf('nnoremap %s :call <SID>do_popup(%d)<CR>', a:prefix, l:id)
  else
    call s:make_all_maps('', l:id)
  endif
  return l:id
endfunction

function s:make_all_maps(prefix, id) abort
  if has_key(g:popsikey, a:id)
    const l:group = g:popsikey[a:id]
    for l:item in l:group.maps
      let l:flags = split(l:item.flags, '\zs')
      let l:n_loc = index(l:flags, 'n')
      let l:m_loc = index(l:flags, 'm')
      let l:noremap = l:n_loc >= 0 ? l:n_loc > l:m_loc : v:false
      let l:key_seq =
            \ empty(a:prefix)
            \ ? l:group.prefix .. l:item.key
            \ : a:prefix .. l:item.key
      if type(l:item.action) is# v:t_string
        execute printf('n%smap %s %s',
              \ l:noremap ? 'nore' : '',
              \ l:key_seq,
              \ escape(l:item.action, '|'))
      elseif type(l:item.action) is# v:t_number
        call s:make_all_maps(l:key_seq, l:item.action)
      else
        echomsg 'popsikey: action type' type(l:item.action) 'in action "' l:item.action '" not supported'
      endif
    endfor
  endif
endfunction

function popsikey#extend(id, maps, opts) abort
  if has_key(g:popsikey, a:id)
    const l:group = g:popsikey[a:id]
    const l:extended_maps = deepcopy(a:maps)
          \ ->map({_, m -> extend(#{flags: 'n'}, m)})
    call extend(l:group.maps, l:extended_maps)
    call extend(l:group.opts, a:opts)
    let l:group.keys = deepcopy(l:group.maps)->map({_, v -> v.key})
    if !has('popupwin')
      call s:make_all_maps('', a:id)
      return
    endif
  endif
endfunction

function popsikey#filter(id, key) abort
  const l:group = g:popsikey[s:popsikey_id]
  if index(l:group.keys, a:key) >= 0
    call popup_close(a:id, a:key)
    return v:true
  else
    return popup_filter_menu(a:id, a:key)
  endif
endfunction

function popsikey#callback(id, result) abort
  const l:id = s:popsikey_id
  let s:popsikey_id = 0
  if a:result isnot# -1
    const l:group = g:popsikey[l:id]
    const l:key_index = index(l:group.keys, a:result)
    const l:index = l:key_index >= 0 ? l:key_index : (a:result - 1)
    const l:item = l:group.maps[index]
    if type(l:item.action) is# v:t_string
      call feedkeys(l:item.action, l:item.flags)
    elseif type(l:item.action) is# v:t_number
      call s:do_popup(l:item.action)
    else
        echomsg 'popsikey: action type' type(l:item.action) 'in action "' l:item.action '" not supported'
    endif
  endif
endfunction

function s:do_popup(id) abort
  let s:popsikey_id = a:id
  const l:group = g:popsikey[s:popsikey_id]
  const l:choices =
        \ deepcopy(l:group.maps)
        \ ->map({i,v -> printf("%s\t%s", v.key, v.info)})
  highlight link PopupSelected Search
  const l:opts = extend(#{
        \ filter: 'popsikey#filter',
        \ callback: 'popsikey#callback',
        \ title: l:group.prefix,
        \ padding: [1,2,1,2],
        \ pos: 'topleft',
        \ line: 'cursor+1',
        \ col: 'cursor',
        \ }, l:group.opts)
  call popup_menu(l:choices, l:opts)
endfunction

let s:id_counter = get(s:, 'id_counter', 1)

function s:get_id() abort
  const l:id = s:id_counter
  let s:id_counter += 1
  return l:id
endfunction
