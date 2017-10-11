module Header exposing (header)

import Html exposing (Html, div, text, img, a, span, ul, li)
import Html.Attributes exposing (class, style, src, height, href)
import Css exposing (asPairs, backgroundColor, hex, padding, px, paddingRight, color, margin, fontSize, displayFlex, alignItems, center, marginRight)
import Css.Colors exposing (white)
import Util exposing (styles)


cMagnetic : Css.Color
cMagnetic =
    hex "283663"


navBar : List (Html msg) -> Html msg
navBar =
    div [ class "navbar navbar-dark", styles [ backgroundColor cMagnetic, padding (px 20) ] ]


logo : Html msg
logo =
    img [ src "/logo.svg", height 25, styles [ paddingRight (px 20) ] ] []


title : List (Html msg) -> Html msg
title =
    span [ styles [ color white, margin (px 0), fontSize (px 25) ] ]


actions : Html msg
actions =
    ul [ class "navbar-nav", styles [ marginRight <| px 25 ] ]
        [ li [ class "nav-item" ]
            [ a [ class "nav-link", href "/logout" ] [ text "Logout" ]
            ]
        ]


header : Html msg
header =
    navBar
        [ title [ text "Redirection Service" ]
        , div [ styles [ displayFlex, alignItems center ] ]
            [ actions
            , logo
            ]
        ]
