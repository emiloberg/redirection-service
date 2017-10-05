module Flash exposing (..)

import Maybe exposing (withDefault)
import Html exposing (..)
import Html.Attributes exposing (..)
import Util exposing (styles)
import Css exposing (position, fixed, top, left, px, zIndex, int, transform, translateX, pct)


none =
    text ""


type Flash
    = Success String
    | Info String
    | Warn String
    | Error String


viewFlashWithClass klass message =
    div [ class klass, styles [ position fixed, top (px 15), left (pct 50), transform (translateX <| pct -50), zIndex (int 100) ] ] [ text message ]


viewFlash : Flash -> Html msg
viewFlash flash =
    case flash of
        Success message ->
            viewFlashWithClass "alert alert-success" message

        Info message ->
            viewFlashWithClass "alert alert-info" message

        Warn message ->
            viewFlashWithClass "alert alert-warning" message

        Error message ->
            viewFlashWithClass "alert alert-danger" message


viewMaybeFlash : Maybe Flash -> Html msg
viewMaybeFlash flash =
    withDefault none (Maybe.map viewFlash flash)
