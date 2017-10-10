module Modal exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


modalId : String
modalId =
    "helpModal"


viewHelpButton : Html msg
viewHelpButton =
    a [ href "", attribute "data-toggle" "modal", attribute "data-target" <| "#" ++ modalId ] [ text "View some examples." ]


viewHelpModal : Html msg
viewHelpModal =
    let
        header =
            div [ class "modal-header" ]
                [ h5 [ class "modal-title" ] [ text "Help and examples" ]
                , button [ type_ "button", class "close", attribute "data-dismiss" "modal" ] [ text "×" ]
                ]

        body =
            div [ class "modal-body" ]
                [ text "body"
                ]

        footer =
            div [ class "modal-footer" ]
                [ button [ type_ "button", class "btn btn-primary", attribute "data-dismiss" "modal" ] [ text "Ok" ]
                ]
    in
        div [ id modalId, class "modal" ]
            [ div [ class "modal-dialog modal-lg" ]
                [ div [ class "modal-content" ]
                    [ header
                    , body
                    , footer
                    ]
                ]
            ]
