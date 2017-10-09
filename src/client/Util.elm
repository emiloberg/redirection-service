module Util exposing (..)

import Css
import Html
import Html.Attributes


styles : List Css.Style -> Html.Attribute msg
styles =
    Css.asPairs >> Html.Attributes.style
