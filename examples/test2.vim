let s:bits = has('num64') ? 64 : 32
let s:mask = s:bits - 1
let s:mask32 = 32 - 1

let s:pow2 = [1]
for s:_ in range(s:mask)
  call add(s:pow2, s:pow2[-1] * 2)
endfor
unlet s:_

function! s:lshift(a, n) abort
  return  a:a * s:pow2[and(a:n, s:mask)]
endfunction

function! s:rshift(a, n) abort
  let n = and(a:n, s:mask)
  return n == 0 ? a:a :
  \  a:a < 0 ? (a:a - s:min) / s:pow2[n] + s:pow2[-2] / s:pow2[n - 1]
  \          : a:a / s:pow2[n]
endfunction

function! s:bin(n) abort
  let l:f = repeat([0.0], 8)
  for l:i in range(8)
    let l:f[i] = 0.0 + and(s:rshift(a:n, l:i), 1)
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

function! s:teacher(n) abort
  if a:n%15 == 0
    return [1, 0, 0, 0]
  elseif a:n%3 == 0
    return [0, 1, 0, 0]
  elseif a:n%5 == 0
    return [0, 0, 1, 0]
  else
    return [0, 0, 0, 1]
  endif
endfunction

function! s:test() abort
  let l:ff = brain#load_model('fizzbuzz.json')
  "call brain#srand(0)

  "let l:patterns = []
  "for l:i in range(1, 100)
  "  call add(l:patterns, [s:bin(i), s:teacher(i)])
  "endfor

  "let l:ff = brain#new_feed()

  "let l:ff.Init(8, 100, 4)

  "call l:ff.Train(l:patterns, 1000, 0.6, 0.4, v:true)

  for l:i in range(1,100)
    let l:r = s:dec(l:ff.Update(s:bin(l:i)))
    if l:r == 0
      echo "FizzBuzz"
    elseif l:r == 1
      echo "Fizz"
    elseif l:r == 2
      echo "Buzz"
    else
      echo l:i
    endif
  endfor
endfunction

call s:test()
