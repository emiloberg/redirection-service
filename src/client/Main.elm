module Main exposing (..)

import Html exposing (..)

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
    }


type alias Model = Int


type Msg
    = Asdf
    | Fdsa


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Asdf ->
            (model, Cmd.none)

        Fdsa ->
            (model, Cmd.none)


view : Model -> Html Msg
view model =
    div []
        [ text "Hello!"
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : (Model, Cmd Msg)
init = 
    (0, Cmd.none)
