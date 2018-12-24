# vim-brain

Neural Network Library for Vim script. This is Vim script port of [goml/gobrain](https://github.com/goml/gobrain).

## Usage

Learning XOR in Vim script.

```vim
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
```

## Installation

```vim
Plug 'mattn/vim-brain'
```

## License

MIT

## Author

Yasuhiro Matsuoto (a.k.a. mattn)
