let s:base = {
\  'NInputs': 0,
\  'NHiddens': 0,
\  'NOutputs': 0,
\  'Regression': v:false,
\  'InputActivations': [],
\  'HiddenActivations': [],
\  'OutputActivations': [],
\  'Contexts': [],
\  'InputWeights': [],
\  'OutputWeights': [],
\  'InputChanges': [],
\  'OutputChanges': [],
\}

function! s:base.Init(inputs, hiddens, outputs) abort
  let self.NInputs = a:inputs + 1
  let self.NHiddens = a:hiddens + 1
  let self.NOutputs = a:outputs

  let self.InputActivations = s:vector(self.NInputs, 1.0)
  let self.HiddenActivations = s:vector(self.NHiddens, 1.0)
  let self.OutputActivations = s:vector(self.NOutputs, 1.0)

  let self.InputWeights = s:matrix(self.NInputs, self.NHiddens)
  let self.OutputWeights = s:matrix(self.NHiddens, self.NOutputs)

  for l:i in range(self.NInputs)
    for l:j in range(self.NHiddens)
      let self.InputWeights[l:i][l:j] = s:random(-1.0, 1.0)
    endfor
  endfor

  for l:i in range(self.NHiddens)
    for l:j in range(self.NOutputs)
      let self.OutputWeights[l:i][l:j] = s:random(-1.0, 1.0)
    endfor
  endfor

  let self.InputChanges = s:matrix(self.NInputs, self.NHiddens)
  let self.OutputChanges = s:matrix(self.NHiddens, self.NOutputs)
endfunction

function! s:base.SetContexts(nContexts, initValues) abort
  let initValues = a:initValues == v:null ? [] : a:initValues
  if empty(initValues)
    let initValues = map(repeat([0.0], a:nContexts), 's:vector(self.NHiddens, 0.5)')
  endif
  let self.Contexts = initValues
endfunction

function s:base.Update(inputs) abort
  if len(a:inputs) != self.NInputs-1
    throw 'Error: wrong number of inputs'
  endif

  for l:i in range(self.NInputs-1)
    let self.InputActivations[l:i] = a:inputs[l:i]
  endfor

  for l:i in range(self.NHiddens-1)
    let l:sum = 0.0

    for l:j in range(self.NInputs)
      let l:sum += self.InputActivations[l:j] * self.InputWeights[l:j][l:i]
    endfor

    for l:k in range(len(self.Contexts))
      for l:j in range(self.NHiddens-1)
        let l:sum += self.Contexts[l:k][l:j]
      endfor
    endfor
    let self.HiddenActivations[l:i] = s:sigmoid(l:sum)
  endfor

  if len(self.Contexts) > 0
    for l:i in reverse(range(1, len(self.Contexts)-1))
      let self.Contexts[l:i] = self.Contexts[l:i-1]
    endfor
    let self.Contexts[0] = self.HiddenActivations
  endif

  for l:i in range(self.NOutputs)
    let l:sum = 0.0
    for l:j in range(self.NHiddens)
      let l:sum += self.HiddenActivations[l:j] * self.OutputWeights[l:j][l:i]
    endfor
    let self.OutputActivations[l:i] = s:sigmoid(l:sum)
  endfor

  return self.OutputActivations
endfunction

function! s:base.BackPropagate(targets, lRate, mFactor) abort
  if len(a:targets) != self.NOutputs
    throw 'Error: wrong number of target values'
  endif

  let l:outputDeltas = s:vector(self.NOutputs, 0.0)
  for l:i in range(self.NOutputs)
    let l:outputDeltas[l:i] = s:dsigmoid(self.OutputActivations[l:i]) * (a:targets[l:i] - self.OutputActivations[l:i])
  endfor

  let l:hiddenDeltas = s:vector(self.NHiddens, 0.0)
  for l:i in range(self.NHiddens)
    let l:e = 0.0

    for l:j in range(self.NOutputs)
      let l:e += outputDeltas[l:j] * self.OutputWeights[l:i][l:j]
    endfor
    let l:hiddenDeltas[l:i] = s:dsigmoid(self.HiddenActivations[l:i]) * l:e
  endfor

  for l:i in range(self.NHiddens)
    for l:j in range(self.NOutputs)
      let l:change = l:outputDeltas[l:j] * self.HiddenActivations[l:i]
      let self.OutputWeights[l:i][l:j] = self.OutputWeights[l:i][l:j] + a:lRate*change + a:mFactor*self.OutputChanges[l:i][l:j]
      let self.OutputChanges[l:i][l:j] = l:change
    endfor
  endfor

  for l:i in range(self.NInputs)
    for l:j in range(self.NHiddens)
      let l:change = l:hiddenDeltas[l:j] * self.InputActivations[l:i]
      let self.InputWeights[l:i][l:j] = self.InputWeights[l:i][l:j] + a:lRate*l:change + a:mFactor*self.InputChanges[l:i][l:j]
      let self.InputChanges[l:i][l:j] = l:change
    endfor
  endfor

  let l:e = 0.0

  for l:i in range(len(a:targets))
    let l:e += 0.5 * pow(a:targets[l:i]-self.OutputActivations[l:i], 2.0)
  endfor
  return l:e
endfunction

function s:base.Train(patterns, iterations, lRate, mFactor, debug) abort
  let l:errors = repeat([0.0], a:iterations)

  for l:i in range(a:iterations)
    let l:e = 0.0 
    for l:p in a:patterns
      call self.Update(l:p[0])
      let l:e += self.BackPropagate(l:p[1], a:lRate, a:mFactor)
    endfor

    let l:errors[l:i] = l:e

    if a:debug && l:i%1000 == 0
      echo l:i l:e
    endif
  endfor

  return l:errors
endfunction

function! s:base.Test(patterns) abort
  for l:p in a:patterns
    echo l:p[0] "->" self.Update(l:p[0]) " : " l:p[1]
  endfor
endfunction

let s:seed = 0
function! s:srand(seed)
  let s:seed = a:seed
endfunction

function! s:rand()
  let s:seed = s:seed * 214013 + 2531011
  let n = (s:seed < 0 ? s:seed - 0x80000000 : s:seed) / 0x10000 % 0x8000
  return 1.0 * n / 0x8000
endfunction

function! s:random(a, b) abort
  return (a:b-a:a)*s:rand() + a:a
endfunction

function! s:matrix(i, j) abort
  return map(repeat([0.0], a:i), 'repeat([0.0], a:j)')
endfunction

function! s:vector(i, fill) abort
  return map(repeat([0.0], a:i), 'a:fill')
endfunction

function! s:sigmoid(x) abort
  return 1.0 / (1.0 + exp(-a:x))
endfunction

function! s:dsigmoid(y) abort
  return a:y * (1.0 - a:y)
endfunction

function! brain#srand(seed) abort
  call s:srand(a:seed)
endfunction

function! brain#load_model(filename) abort
  let obj = json_decode(join(readfile(a:filename), "\n"))
  let l:feed = deepcopy(s:base)
  let l:feed.NInputs = l:obj.NInputs
  let l:feed.NHiddens = l:obj.NHiddens
  let l:feed.NOutputs = l:obj.NOutputs
  let l:feed.Regression = l:obj.Regression
  let l:feed.InputActivations = l:obj.InputActivations
  let l:feed.HiddenActivations = l:obj.HiddenActivations
  let l:feed.OutputActivations = l:obj.OutputActivations
  let l:feed.Contexts = l:obj.Contexts == v:null ? [] : l:obj.Contexts
  let l:feed.InputWeights = l:obj.InputWeights
  let l:feed.OutputWeights = l:obj.OutputWeights
  let l:feed.InputChanges = l:obj.InputChanges
  let l:feed.OutputChanges = l:obj.OutputChanges
  return l:feed
endfunction

function! brain#new_feed() abort
  return deepcopy(s:base)
endfunction
