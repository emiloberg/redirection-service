module Flash exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Util exposing (styles)
import List exposing (reverse)
import Css exposing (position, fixed, top, left, px, zIndex, int, transform, translateX, pct)


none : Html msg
none =
    text ""


type Flash
    = Success String
    | Info String
    | Warn String
    | Error String


viewFlashWithClass : String -> String -> Html msg
viewFlashWithClass klass message =
    div [ class klass ] [ text message ]


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


viewFlashes : List Flash -> Html msg
viewFlashes flashes =
    div [ styles [ position fixed, top (px 15), left (pct 50), transform (translateX <| pct -50), zIndex (int 100) ] ]
        (List.map viewFlash <| reverse flashes)
