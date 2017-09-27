module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Date exposing (Date)
import Date.Extra.Format as Format exposing (format, isoDateFormat, isoTimeFormat)
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


type Column
    = From
    | To
    | Variety
    | Why
    | Who
    | Created
    | Updated


type alias Model =
    { rules : List Rule
    , sortColumn : Column
    , sortDirection : Direction
    }


type Msg
    = SortByColumn Column


type Direction
    = Ascending
    | Descending


sortByColumn : Column -> Direction -> List Rule -> List Rule
sortByColumn column direction rules =
    let
        sorter : Rule -> String
        sorter =
            case column of
                From ->
                    .from

                To ->
                    .to

                Variety ->
                    .variety >> toString

                Why ->
                    .why

                Who ->
                    .who

                Created ->
                    .created >> dateToString

                Updated ->
                    .updated >> dateToString

        maybeReverse : Direction -> List a -> List a
        maybeReverse sortDirection =
            case sortDirection of
                Descending ->
                    List.reverse

                Ascending ->
                    identity
    in
        rules |> List.sortBy sorter |> maybeReverse direction


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        reverseDirection =
            case model.sortDirection of
                Ascending ->
                    Descending

                Descending ->
                    Ascending
    in
        case msg of
            SortByColumn column ->
                if column == model.sortColumn then
                    ( { model | sortDirection = reverseDirection }, Cmd.none )
                else
                    ( { model | sortColumn = column, sortDirection = Ascending }, Cmd.none )


dateToString : Date -> String
dateToString date =
    format config "%Y-%m-%d %H:%M" date


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
    let
        arrow =
            case model.sortDirection of
                Ascending ->
                    " ↓"

                Descending ->
                    " ↑"

        showArrow column =
            if column == model.sortColumn then
                arrow
            else
                ""
    in
        table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [ onClick <| SortByColumn From ] [ text <| "From" ++ showArrow From ]
                    , th [ onClick <| SortByColumn To ] [ text <| "To" ++ showArrow To ]
                    , th [ onClick <| SortByColumn Variety ] [ text <| "Variety" ++ showArrow Variety ]
                    , th [ onClick <| SortByColumn Why ] [ text <| "Why" ++ showArrow Why ]
                    , th [ onClick <| SortByColumn Who ] [ text <| "Who" ++ showArrow Who ]
                    , th [ onClick <| SortByColumn Created ] [ text <| "Created" ++ showArrow Created ]
                    , th [ onClick <| SortByColumn Updated ] [ text <| "Updated" ++ showArrow Updated ]
                    ]
                ]
            , tbody []
                (model.rules
                    |> sortByColumn model.sortColumn model.sortDirection
                    |> List.map ruleToRow
                )
            ]


init : ( Model, Cmd Msg )
init =
    ( { rules =
            [ Rule "/boll" "/404" Permanent "Because" "me" (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0)) (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0))
            , Rule "/apa" "/404" Temporary "asdf" "you" (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0)) (Date.fromString "2016-01-01" |> Result.withDefault (Date.fromTime 0))
            ]
      , sortColumn = From
      , sortDirection = Ascending
      }
    , Cmd.none
    )
