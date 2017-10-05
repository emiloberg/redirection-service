module Util exposing (..)

import Css
import Html.Attributes


styles =
    Css.asPairs >> Html.Attributes.style
