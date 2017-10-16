module Util exposing (..)

import Css
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Json


styles : List Css.Style -> Html.Attribute msg
styles =
    Css.asPairs >> Html.Attributes.style


anyListMember : List a -> List a -> Bool
anyListMember items list =
    List.any (\item -> List.member item items) list


removeFromList : List a -> List a -> List a
removeFromList itemsToRemove list =
    List.filter (\item -> not (List.member item itemsToRemove)) list


onClickPreventDefault : msg -> Html.Attribute msg
onClickPreventDefault message =
    let
        config =
            { stopPropagation = False
            , preventDefault = True
            }
    in
        Html.Events.onWithOptions "click" config (Json.succeed message)
