module PartialOrComplete exposing
    ( PartialOrComplete(..)
    , value, completeElseOnPartial, isComplete
    , onPartialMapFlat
    , recurseUntilComplete
    , completeOnJust, justOnComplete
    , completeOnOk, okOnComplete
    )

{-| We there, yet?

@docs PartialOrComplete


## observe

@docs value, completeElseOnPartial, isComplete


## alter

@docs onPartialMapFlat


## recurse

@docs recurseUntilComplete


## transform


### `Maybe`

@docs completeOnJust, justOnComplete


### `Result`

@docs completeOnOk, okOnComplete

-}


{-| Either we're done and have a `Complete` result,
or we just have incomplete → `Partial` information.

Check the [readme](https://dark.elm.dmy.fr/packages/lue-bird/elm-partial-or-complete/latest/) for use-cases

-}
type PartialOrComplete partial complete
    = Partial partial
    | Complete complete


{-| Conveniently check whether a [`PartialOrComplete`](#PartialOrComplete) is `Complete`.

Prefer `case..of` except for situations like

    import Linear exposing (Direction(..))
    import List.Linear

    listMember : element -> (List element -> Bool)
    listMember needle list =
        list
            |> List.Linear.foldUntilCompleteFrom ()
                Up
                (\element () ->
                    if element == needle then
                        Complete ()

                    else
                        Partial ()
                )
            |> PartialOrComplete.isComplete

-}
isComplete : PartialOrComplete partial_ complete_ -> Bool
isComplete =
    \partialOrComplete ->
        case partialOrComplete of
            Complete _ ->
                True

            Partial _ ->
                False


{-| In case the [`PartialOrComplete`](#PartialOrComplete)
is `Partial`, do another step, arriving at another [`PartialOrComplete`](#PartialOrComplete) state.

This is like an "andThen" from the `Partial` case.

-}
onPartialMapFlat :
    (partial -> PartialOrComplete partialMapped complete)
    ->
        (PartialOrComplete partial complete
         -> PartialOrComplete partialMapped complete
        )
onPartialMapFlat partialChange =
    \partialOrComplete ->
        case partialOrComplete of
            Partial partial ->
                partial |> partialChange

            Complete complete ->
                complete |> Complete


{-| Recover the case where the [`PartialOrComplete`](#PartialOrComplete) is `Partial`
to return a `complete` value.

    import Linear exposing (Direction(..))
    import List.Linear

    listTake : Int -> (List element -> List element)
    listTake lengthToTake list =
        list
            |> List.Linear.foldUntilCompleteFrom []
                Down
                (\element takenSoFar ->
                    if takenSoFar.length >= lengthToTake then
                        takenSoFar |> Complete

                    else
                        { length = takenSoFar.length + 1
                        , list = element :: takenSoFar
                        }
                            |> Partial
                )
            -- succeed even if we've taken less then the maximum amount of elements
            |> PartialOrComplete.completeElseOnPartial .list

Note: `PartialOrComplete.completeElseOnPartial identity`
can be simplified to [`PartialOrComplete.value`](#value)

-}
completeElseOnPartial : (partial -> complete) -> (PartialOrComplete partial complete -> complete)
completeElseOnPartial partialToComplete =
    \partialOrComplete ->
        case partialOrComplete of
            Complete complete ->
                complete

            Partial partial ->
                partial |> partialToComplete


{-| Treat a `Partial` result the same as if it was `Complete`

    [ Partial 3, Complete 10 ] |> List.map PartialOrComplete.value
    --> [ 3, 10 ]

Often used after a `...UntilComplete.foldUpFrom`:

    import Linear exposing (Direction(..))
    import List.Linear
    import Set exposing (Set)

    whileValidMove : List Movement -> Set ValidMove
    whileValidMove movementRay =
        movementRay
            |> List.Linear.foldUntilCompleteFrom Set.empty
                Up
                (\movement ->
                    case movement |> toValidMove of
                        Nothing ->
                            Complete

                        Just validMove ->
                            \soFar -> soFar |> Set.insert validMove |> Partial
                )
            -- succeed even if we've reached the end of the board
            |> PartialOrComplete.value

For more control over how to recover from a `Partial` case, use a `case..of`
or [`PartialOrComplete.completeElseOnPartial`](#completeElseOnPartial)

-}
value : PartialOrComplete value value -> value
value =
    \partialOrComplete -> partialOrComplete |> completeElseOnPartial identity


{-| `Partial ()` on `Nothing`, `Complete` with the value on `Just`

    import Linear exposing (Direction(..))
    import List.Linear

    [ Nothing, Nothing, Just 55, Nothing ]
        |> List.Linear.foldUntilCompleteFrom ()
            Up
            (\element () -> element |> PartialOrComplete.completeOnJust)
        |> PartialOrComplete.justOnComplete
    --> Just 55

-}
completeOnJust : Maybe complete -> PartialOrComplete () complete
completeOnJust =
    \maybe ->
        case maybe of
            Nothing ->
                Partial ()

            Just complete ->
                complete |> Complete


{-| `Nothing` on `Partial`, `Just` the complete value on `Complete`.

    import Linear exposing (Direction(..))
    import List.Linear

    [ Nothing, Nothing, Just 55, Nothing ]
        |> List.Linear.foldUntilCompleteFrom ()
            Up
            (\element () -> element |> PartialOrComplete.completeOnJust)
        |> PartialOrComplete.justOnComplete
    --> Just 55

-}
justOnComplete : PartialOrComplete partial_ complete -> Maybe complete
justOnComplete =
    \partialOrComplete ->
        case partialOrComplete of
            Partial _ ->
                Nothing

            Complete complete ->
                complete |> Just


{-| `Partial` with the error on `Err`, `Complete` with the value on `Ok`

    import Linear exposing (Direction(..))
    import List.Linear

    [ Err "a", Err "b", Ok 55, Err "d" ]
        |> List.Linear.foldUntilCompleteFrom ()
            Up
            (\element _ -> element |> PartialOrComplete.completeOnOk)
        |> PartialOrComplete.okOnComplete
    --> Ok 55

-}
completeOnOk : Result partial complete -> PartialOrComplete partial complete
completeOnOk =
    \maybe ->
        case maybe of
            Err partial ->
                Partial partial

            Ok complete ->
                complete |> Complete


{-| `Err` with the value on `Partial`, `Ok` with the value on `Complete`.

    import Linear exposing (Direction(..))
    import List.Linear

    [ Err "a", Err "b", Ok 55, Err "d" ]
        |> List.Linear.foldUntilCompleteFrom ()
            Up
            (\element _ -> element |> PartialOrComplete.completeOnOk)
        |> PartialOrComplete.okOnComplete
    --> Ok 55

-}
okOnComplete : PartialOrComplete partial complete -> Result partial complete
okOnComplete =
    \partialOrComplete ->
        case partialOrComplete of
            Partial partial ->
                partial |> Err

            Complete complete ->
                complete |> Ok


{-| Create a tail-recursive function of one argument

    pow : Int -> Int -> Int
    pow base exponent =
        { result = 1, exponent = abs exponent }
            |> PartialOrComplete.recurseUntilComplete
                (\state ->
                    case state.exponent of
                        0 ->
                            Complete state.result

                        exponentAtLeast1 ->
                            Partial
                                { exponent = exponentAtLeast1 - 1
                                , result = state.result * base
                                }
                )

-}
recurseUntilComplete : (partial -> PartialOrComplete partial complete) -> (partial -> complete)
recurseUntilComplete step =
    let
        go : PartialOrComplete partial complete -> complete
        go partialOrComplete =
            case partialOrComplete of
                Complete complete ->
                    complete

                Partial a ->
                    go (step a)
    in
    \initialPartial -> step initialPartial |> go
