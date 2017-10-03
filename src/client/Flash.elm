module Flash exposing (..)

import Maybe exposing (withDefault)
import Html exposing (..)
import Html.Attributes exposing (..)


none =
    text ""


type Flash
    = Success String
    | Error String


viewFlash : Flash -> Html msg
viewFlash flash =
    case flash of
        Success flashMessage ->
            div [ class "alert alert-success" ] [ text flashMessage ]

        Error flashMessage ->
            div [ class "alert alert-danger" ] [ text flashMessage ]


viewMaybeFlash : Maybe Flash -> Html msg
viewMaybeFlash flash =
    withDefault none (Maybe.map viewFlash flash)
