module Header exposing (header)

import Html exposing (Html, div, text, img, a, span)
import Html.Attributes exposing (class, style, src, height)
import Css exposing (asPairs, backgroundColor, hex, padding, px, paddingRight, color, margin, fontSize)
import Css.Colors exposing (white)


styles =
    asPairs >> style


cMagnetic =
    hex "283663"


navBar =
    div [ class "navbar navbar-dark", styles [ backgroundColor cMagnetic, padding (px 20) ] ]


logo =
    img [ src "/logo.svg", height 25, styles [ paddingRight (px 20) ] ] []


title =
    span [ styles [ color white, margin (px 0), fontSize (px 25) ] ]


header : Html msg
header =
    navBar
        [ title [ text "Redirection Service" ]
        , logo
        ]
