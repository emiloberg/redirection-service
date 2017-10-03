module Rule exposing (..)

import Graph
import Http
import Date exposing (Date)
import Date.Extra.Format as Format exposing (format)
import Date.Extra.Config.Config_en_us exposing (config)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline
import Debug
import Result exposing (andThen)
import Regex exposing (contains, regex)


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


type alias MutationRule =
    { from : String
    , to : String
    , variety : Variety
    , why : String
    , who : String
    , isRegex : Bool
    }


strToVariety : String -> Variety
strToVariety str =
    if str == "Temporary" then
        Temporary
    else if str == "Permanent" then
        Permanent
    else
        Temporary


dateToString : Date -> String
dateToString date =
    format config "%Y-%m-%d %H:%M" date


resultToBool : Result a b -> Bool
resultToBool result =
    case result of
        Ok value ->
            True

        Err value ->
            False



-- EditRule (Just rule.ruleId)
-- EditRule Nothing


type RuleValidationError
    = FromIsEmpty
    | FromIsNotAPath
    | ToIsEmpty
    | WhyIsEmpty


validateRule : MutationRule -> Result RuleValidationError MutationRule
validateRule rule =
    let
        validate validationError isValid rule =
            if (isValid rule) then
                Ok rule
            else
                Err validationError

        isPath =
            contains <| regex "^(\\/[^\\s\\/]+)+$"
    in
        Ok rule
            |> andThen (validate FromIsEmpty (.from >> String.isEmpty >> not))
            |> andThen (validate FromIsNotAPath (.from >> isPath))
            |> andThen (validate ToIsEmpty (.to >> String.isEmpty >> not))
            |> andThen (validate WhyIsEmpty (.why >> String.isEmpty >> not))


viewAddRuleRow : msg -> (MutationRule -> msg) -> (MutationRule -> msg) -> MutationRule -> Html msg
viewAddRuleRow cancelMessage saveMessage updateMessage rule =
    let
        updateFrom value =
            updateMessage { rule | from = value }

        updateTo value =
            updateMessage { rule | to = value }

        updateIsRegex =
            updateMessage
                { rule | isRegex = not rule.isRegex }

        updateVariety value =
            updateMessage { rule | variety = (strToVariety value) }

        updateWhy value =
            updateMessage { rule | why = value }
    in
        tr [ class "table-info" ]
            [ td [] [ input [ value rule.from, placeholder "From", onInput updateFrom ] [] ]
            , td [] [ input [ value rule.to, placeholder "To", onInput updateTo ] [] ]
            , td [] [ input [ type_ "checkbox", checked rule.isRegex, onClick updateIsRegex ] [] ]
            , td []
                [ select [ class "form-control", onInput updateVariety ]
                    [ option [ value << toString <| Permanent, (selected (rule.variety == Permanent)) ] [ text << toString <| Permanent ]
                    , option [ value << toString <| Temporary, (selected (rule.variety == Temporary)) ] [ text << toString <| Temporary ]
                    ]
                ]
            , td [] [ input [ value rule.why, placeholder "Why", onInput updateWhy ] [] ]
            , td [] []
            , td [] []
            , td [] []
            , td []
                [ button [ class "btn btn-outline-warning", onClick <| saveMessage rule ] [ text "💾" ]
                , button [ class "btn btn-outline-warning", onClick <| cancelMessage ] [ text "🚫" ]
                ]
            ]


viewRuleRow startEdit rule =
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


viewRuleEditRow doneEdit rule =
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


ruleToRow : Bool -> msg -> msg -> Rule -> Html msg
ruleToRow shouldBeEditable startEdit doneEdit rule =
    if shouldBeEditable then
        viewRuleEditRow doneEdit rule
    else
        viewRuleRow startEdit rule


rulesDecoder : Decoder (List Rule)
rulesDecoder =
    Decode.at [ "data", "allRules", "edges" ] <| Decode.list (Decode.field "node" ruleDecoder)


varietyDecoder : Decoder Variety
varietyDecoder =
    Decode.map strToVariety Decode.string


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


addRule : MutationRule -> Http.Request Rule
addRule mutationRule =
    Graph.queryWithVars
        """
          mutation CreateRule($from: String!, $to: String!, $kind: String!, $why: String!, $who: String!, $isRegex: Boolean!) {
            createRule(input: {rule: {from: $from, to: $to, kind: $kind, why: $why, who: $who, isRegex: $isRegex}}) {
              rule {
                id
                from
                to
                kind
                why
                who
                isRegex
                created
                updated
              }
            }
          }
        """
        [ ( "from", Encode.string mutationRule.from )
        , ( "to", Encode.string mutationRule.to )
        , ( "kind", Encode.string (toString mutationRule.variety) )
        , ( "why", Encode.string mutationRule.why )
        , ( "who", Encode.string "not@real.user" ) --todo change me
        , ( "isRegex", Encode.bool mutationRule.isRegex )
        ]
        (Decode.at
            [ "data", "createRule", "rule" ]
            ruleDecoder
        )
