module Main exposing (..)

import Html exposing (..)
import Date exposing (Date)
import Date.Extra.Format as Format exposing (format)
import Date.Extra.Config.Config_en_us exposing (config)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type Variety
    = Permanent
    | Temporary


type alias Rule =
    { from : String
    , to : String
    , variety : Variety
    , why : String
    , who : String
    , created : Date
    , updated : Date
    }


type alias Model =
    { rules : List Rule
    }


type Msg
    = Asdf
    | Fdsa


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Asdf ->
            ( model, Cmd.none )

        Fdsa ->
            ( model, Cmd.none )


dateToString : Date -> String
dateToString date =
    format config config.format.dateTime date


ruleToRow : Rule -> Html msg
ruleToRow rule =
    tr []
        [ td [] [ text rule.from ]
        , td [] [ text rule.to ]
        , td [] [ text <| toString <| rule.variety ]
        , td [] [ text rule.why ]
        , td [] [ text rule.who ]
        , td [] [ text <| dateToString <| rule.created ]
        , td [] [ text <| dateToString <| rule.updated ]
        ]


view : Model -> Html Msg
view model =
    table []
        [ thead []
            [ tr []
                [ th [] [ text "From" ]
                , th [] [ text "To" ]
                , th [] [ text "Variety" ]
                , th [] [ text "Why" ]
                , th [] [ text "Who" ]
                , th [] [ text "Created" ]
                , th [] [ text "Updated" ]
                ]
            ]
        , tbody []
            (List.map
                ruleToRow
                model.rules
            )
        ]


init : ( Model, Cmd Msg )
init =
    ( Model
        [ Rule "/" "/404" Permanent "Because" "me" (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0)) (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0))
        , Rule "/" "/404" Temporary "asdf" "you" (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0)) (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0))
        ]
    , Cmd.none
    )
