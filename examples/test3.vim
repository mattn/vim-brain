let s:base = fnamemodify(expand('<sfile>:h'), ':p')

function! s:enc(l, n) abort
  let l:f = repeat([0.0], len(a:l))
  for l:i in range(len(a:l))
    if a:l[l:i] == a:n
      let l:f[l:i] = 1.0
    endif
  endfor
  return l:f
endfunction

function! s:dec(v) abort
  let [l:maxi, l:maxv] = [0, 0.0]
  for l:i in range(len(a:v))
    if a:v[l:i] > l:maxv
      let l:maxv = a:v[l:i]
      let l:maxi = l:i
    endif
  endfor
  return l:maxi
endfunction

let s:kws = json_decode(join(readfile(s:base . '/keywords.json'), "\n"))
let s:lng = json_decode(join(readfile(s:base . '/languages.json'), "\n"))

function! s:keywords(code) abort
  let l:kwf = repeat([0.0], len(s:kws))

  let l:words = []
  call substitute(a:code, '\<\w\+', '\=add(l:words, submatch(0)) == [] ? "" : ""', 'g')
  let l:kc = 0.0

  for l:v in l:words
    let l:n = index(s:kws, l:v)
    if l:n != -1
      let l:kwf[l:n] += 1.0
      let l:kc += 1.0
    endif
  endfor

  for l:i in range(len(l:kwf))
    if l:kwf[l:i] > 0.0
      let l:kwf[l:i] = l:kwf[l:i] / kc
    endif
  endfor
  return l:kwf
endfunction

function! s:test() abort
  let l:ff = brain#load_model(s:base . '/guesslang.json')
  let l:code = join(
  \ [
  \ "#include <iostream>",
  \ "#include <string>",
  \ "#include <algorithm>",
  \ "",
  \ "int",
  \ "main(int argc, char* argv[]) {",
  \ "std::vector<std::string> v;",
  \ "return 0;",
  \ "}",
  \ ],
  \ "\n")
  let l:input = s:keywords(l:code)
  let l:r = s:dec(l:ff.Update(l:input))
  echo s:lng[l:r]
endfunction

call s:test()
