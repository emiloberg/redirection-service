module Util exposing (..)

import Css
import Html
import Html.Attributes


styles : List Css.Style -> Html.Attribute msg
styles =
    Css.asPairs >> Html.Attributes.style


anyListMember : List a -> List a -> Bool
anyListMember items list =
    List.any (\item -> List.member item items) list


removeFromList : List a -> List a -> List a
removeFromList itemsToRemove list =
    List.filter (\item -> not (List.member item itemsToRemove)) list
