port module Confirm exposing (..)


port askToConfirm : String -> Cmd msg


port confirmationResponses : (Bool -> msg) -> Sub msg
