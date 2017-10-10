module Modal exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


modalId : String
modalId =
    -- An id to select and toggle the modal on. The random suffix makes conflicts unlikely.
    "helpModal-9fec3a447441"


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
                [ p [ class "lead" ] [ text "There are two types of rules, plain and regex - you should probably use the former." ]
                , h6 [ class "modal-title" ] [ text "Plain" ]
                , p [] [ text "Plain rules simply map a path (e.g. \"/some/path\") on izettle.com to a different path or url." ]
                , h6 [ class "modal-title" ] [ text "Regex" ]
                , p [] [ text "Regex rules are for advanced path matching and bulk operations." ]
                , h6 [ class "modal-title" ] [ text "Matching tokens" ]
                , p [] [ text "There is a special token \"{country}\" which will match any valid lokale for izettle.com." ]
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
