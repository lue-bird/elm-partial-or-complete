# [`PartialOrComplete`](PartialOrComplete)

```elm
| Partial partial -- keep going
| Complete complete -- done
```

– a _pattern_ used in

  - ```elm
    type Step folded
        = Continue folded
        | Done folded
    
    stoppableFold :
       folded
    -> (element -> folded -> Step folded)
    -> Structure element
    -> folded
    ```
      - [`List.Extra.stoppableFold`](https://dark.elm.dmy.fr/packages/elm-community/list-extra/latest/List-Extra#stoppableFold)
      - [`FastDict.stoppableFold`](https://dark.elm.dmy.fr/packages/miniBill/elm-fast-dict/1.1.0/FastDict#stoppableFold)
  - ```elm
    type Step state complete
        = Loop state
        | Done complete
    
    loop :
       state
    -> (state -> Magic (Step state complete))
    -> Magic complete
    ```
      - [`Parser.loop`](https://dark.elm.dmy.fr/packages/elm/parser/latest/Parser#loop)
      - [`Bytes.Decode.loop`](https://dark.elm.dmy.fr/packages/elm/bytes/1.0.8/Bytes-Decode#loop)
      - [`Bytes.Parser.loop`](https://dark.elm.dmy.fr/packages/zwilias/elm-bytes-parser/1.0.0/Bytes-Parser#loop)
      - [`Parser.Recoverable.loop`](https://dark.elm.dmy.fr/packages/the-sett/parser-recoverable/1.0.0/Parser-Recoverable#loop),
      - [`State.tailRec(M)`](https://dark.elm.dmy.fr/packages/folkertdev/elm-state/latest/State#tailRec)
  - ```elm
    type Step
        = InProgress InProgress
        | Done Complete
    
    step : InProgress -> Step
    ```
    step-by-step testing, benchmarking, parsing, simplifying/shrinking, evaluating, ...

Maybe it makes sense to have a shared type in a shared place?
With shared documentation and helpers?

## where [`PartialOrComplete`](PartialOrComplete) is already being used

Step through a structure; stop when you're done.

  - [`List.Linear.foldUntilCompleteFrom`](https://dark.elm.dmy.fr/packages/lue-bird/elm-linear-direction/latest/List-Linear#foldUntilCompleteFrom)
  - [`KeysSet.foldUntilCompleteFrom`](https://dark.elm.dmy.fr/packages/lue-bird/elm-keysset/latest/KeysSet#foldUntilCompleteFrom)

Suggestions & additions welcome!

## reasons for avoiding it

  - You don't want to require users to manually install this package
    for just the stoppable type and helpers?
  
  - In your domain, variant names can be more specific and descriptive
    than "partial" and "complete"?

  - You like avoiding package dependencies?
    → You can expect this package to not have breaking changes

  - You have the same intermediate and complete types and use
    ```elm
    type InProgress
        = Atom { info : Info, report : Maybe Report }
        | Structured (List InProgress)
    
    step : InProgress -> InProgress
    isDone : InProgress -> Bool
    ```
    → I do suggest looking into
    ```elm
    type Thing report
        = Atom { info : Info, report : report }
        | Structured (List (Thing report))
    
    step : Thing (Maybe Report) -> PartialOrComplete (Thing (Maybe Report)) (Thing Report)
    ```
    I'd say that's a tiny tiny bit nicer because you can't miss that you're already done.
