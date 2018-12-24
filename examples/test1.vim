function! s:test() abort
  call brain#srand(0)

  let l:patterns = [
  \ [[0.0, 0.0], [0.0]],
  \ [[0.0, 1.0], [1.0]],
  \ [[1.0, 0.0], [1.0]],
  \ [[1.0, 1.0], [0.0]],
  \]

  let l:ff = brain#new_feed()

  call l:ff.Init(2, 2, 1)

  call l:ff.Train(l:patterns, 1000, 0.6, 0.4, v:false)

  call l:ff.Test(l:patterns)
endfunction

call s:test()
