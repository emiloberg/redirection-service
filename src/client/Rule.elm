module Rule exposing (..)

import Graph
import Http
import Date exposing (Date)
import Date.Extra.Format as Format exposing (format)
import Date.Extra.Config.Config_en_us exposing (config)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline


type Variety
    = Permanent
    | Temporary


type alias RuleId =
    Int


type alias Rule =
    { ruleId : RuleId
    , from : String
    , to : String
    , variety : Variety
    , why : String
    , who : String
    , isRegex : Bool
    , created : Date
    , updated : Date
    }


dateToString : Date -> String
dateToString date =
    format config "%Y-%m-%d %H:%M" date



-- EditRule (Just rule.ruleId)
-- EditRule Nothing


ruleToRow : Bool -> msg -> msg -> Rule -> Html msg
ruleToRow shouldBeEditable startEdit doneEdit rule =
    let
        toRow rule =
            tr []
                [ td [] [ text rule.from ]
                , td [] [ text rule.to ]
                , td [] [ input [ type_ "checkbox", disabled True, checked rule.isRegex ] [] ]
                , td [] [ text <| toString <| rule.variety ]
                , td [] [ text rule.why ]
                , td [] [ text rule.who ]
                , td [] [ text <| dateToString <| rule.created ]
                , td [] [ text <| dateToString <| rule.updated ]
                , td []
                    [ button [ class "btn btn-outline-warning", onClick <| startEdit ] [ text "✏️" ]
                    ]
                ]

        toEditRow rule =
            tr [ class "table-info" ]
                [ td [] [ input [ value rule.from, placeholder "From" ] [] ]
                , td [] [ input [ value rule.to, placeholder "To" ] [] ]
                , td [] [ input [ type_ "checkbox", checked rule.isRegex ] [] ]
                , td []
                    [ select [ class "form-control" ]
                        [ option [ value << toString <| Permanent ] [ text << toString <| Permanent ]
                        , option [ value << toString <| Temporary ] [ text << toString <| Temporary ]
                        ]
                    ]
                , td [] [ input [ value rule.why, placeholder "Why" ] [] ]
                , td [] [ text rule.who ]
                , td [] [ text <| dateToString <| rule.created ]
                , td [] [ text <| dateToString <| rule.updated ]
                , td []
                    [ button [ class "btn btn-outline-warning", onClick <| doneEdit ] [ text "💾" ]
                    , button [ class "btn btn-outline-warning", onClick <| doneEdit ] [ text "🚫" ]
                    , button [ class "btn btn-outline-warning", onClick <| doneEdit ] [ text "🗑" ]
                    ]
                ]
    in
        if shouldBeEditable then
            toEditRow rule
        else
            toRow rule


rulesDecoder : Decoder (List Rule)
rulesDecoder =
    Decode.at [ "data", "allRules", "edges" ] <| Decode.list (Decode.field "node" ruleDecoder)


varietyDecoder : Decoder Variety
varietyDecoder =
    Decode.map
        (\str ->
            if str == "Temporary" then
                Temporary
            else if str == "Permanent" then
                Permanent
            else
                -- Todo fix me
                Temporary
        )
        Decode.string


dateDecoder : Decoder Date
dateDecoder =
    let
        convert : String -> Decoder Date
        convert raw =
            case Date.fromString raw of
                Ok date ->
                    Decode.succeed date

                Err error ->
                    Decode.fail error
    in
        Decode.string |> Decode.andThen convert


ruleDecoder : Decoder Rule
ruleDecoder =
    Json.Decode.Pipeline.decode Rule
        |> Json.Decode.Pipeline.required "id" Decode.int
        |> Json.Decode.Pipeline.required "from" Decode.string
        |> Json.Decode.Pipeline.required "to" Decode.string
        |> Json.Decode.Pipeline.required "kind" varietyDecoder
        |> Json.Decode.Pipeline.required "why" Decode.string
        |> Json.Decode.Pipeline.required "who" Decode.string
        |> Json.Decode.Pipeline.required "isRegex" Decode.bool
        |> Json.Decode.Pipeline.required "created" dateDecoder
        |> Json.Decode.Pipeline.required "updated" dateDecoder


getRules : Http.Request (List Rule)
getRules =
    Graph.query
        """
          {
            allRules {
              edges {
                node {
                  id,
                  from,
                  to,
                  kind,
                  why,
                  who,
                  isRegex,
                  created,
                  updated
                }
              }
            }
          }
        """
        rulesDecoder
