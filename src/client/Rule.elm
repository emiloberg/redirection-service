module Rule exposing (..)

import Http
import Date exposing (Date)
import Date.Extra.Format as Format exposing (format)
import Date.Extra.Config.Config_en_us exposing (config)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline
import Result exposing (andThen)
import Util exposing (styles)
import Css
    exposing
        ( display
        , tableRow
        , tableCell
        , backgroundColor
        , hex
        , solid
        , px
        , borderTop3
        , top
        , verticalAlign
        , padding
        , marginRight
        , minWidth
        , textAlign
        , center
        , pct
        , width
        )


wordBreakAll : Css.Style
wordBreakAll =
    Css.property "word-break" "break-all"


type Kind
    = Permanent
    | Temporary


type alias RuleId =
    Int


type alias Rule =
    { ruleId : RuleId
    , from : String
    , to : String
    , kind : Kind
    , why : String
    , who : String
    , isRegex : Bool
    , created : Date
    , updated : Date
    }


type alias MutationRule =
    { from : String
    , to : String
    , kind : Kind
    , why : String
    , who : String
    , isRegex : Bool
    }


cellStyles : List Css.Style
cellStyles =
    [ display tableCell, padding (Css.rem 0.75), verticalAlign top, borderTop3 (px 1) solid (hex "e9ecef") ]


strToKind : String -> Kind
strToKind str =
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


type RuleValidationError
    = FromIsEmpty
    | FromIsNotAPath
    | ToIsEmpty
    | ToIsNotAUri
    | WhyIsEmpty
    | WhyIsTooShort


kindToString : Kind -> String
kindToString variety =
    case variety of
        Permanent ->
            "Permanent (301)"

        Temporary ->
            "Temporary (302)"


viewAddRuleRow : Bool -> msg -> (MutationRule -> msg) -> (MutationRule -> msg) -> MutationRule -> Html msg
viewAddRuleRow showAll cancelMessage saveMessage updateMessage rule =
    let
        updateFrom value =
            updateMessage { rule | from = value }

        updateTo value =
            updateMessage { rule | to = value }

        updateIsRegex =
            updateMessage
                { rule | isRegex = not rule.isRegex }

        updateKind value =
            updateMessage { rule | kind = (strToKind value) }

        updateWhy value =
            updateMessage { rule | why = value }

        primaryCols =
            [ span [ styles cellStyles ] [ input [ value rule.from, placeholder "From", onInput updateFrom, styles [ Css.width <| pct 100 ] ] [] ]
            , span [ styles cellStyles ] [ input [ value rule.to, placeholder "To", onInput updateTo, styles [ Css.width <| pct 100 ] ] [] ]
            , span [ styles <| cellStyles ++ [ textAlign center ] ] [ input [ type_ "checkbox", checked rule.isRegex, onClick updateIsRegex ] [] ]
            , span [ styles cellStyles ]
                [ select [ class "form-control", onInput updateKind ]
                    [ option [ value << toString <| Permanent, (selected (rule.kind == Permanent)) ] [ text <| kindToString Permanent ]
                    , option [ value << toString <| Temporary, (selected (rule.kind == Temporary)) ] [ text <| kindToString Temporary ]
                    ]
                ]
            , span [ styles cellStyles ] [ input [ value rule.why, placeholder "Why", onInput updateWhy, styles [ Css.width <| pct 100 ] ] [] ]
            ]

        extraCols =
            if showAll then
                [ span [ styles cellStyles ] []
                , span [ styles cellStyles ] []
                , span [ styles cellStyles ] []
                ]
            else
                []

        actionCols =
            [ span [ styles cellStyles ]
                [ button [ type_ "button", class "btn btn-success", styles [ marginRight (px 5) ], onClick <| saveMessage rule ] [ text "Save" ]
                , button [ type_ "button", class "btn btn-outline-secondary", onClick <| cancelMessage ] [ text "Cancel" ]
                ]
            ]

        cols =
            primaryCols ++ extraCols ++ actionCols
    in
        Html.form [ styles [ display tableRow ], class "table-active", onSubmit <| saveMessage rule ] cols


viewRuleRow : Bool -> msg -> Rule -> Html msg
viewRuleRow showAll startEdit rule =
    let
        cell extraStyles =
            td [ styles <| [ minWidth <| px 200 ] ++ extraStyles ]

        primaryCols =
            [ cell [ wordBreakAll ] [ text rule.from ]
            , cell [ wordBreakAll ] [ text rule.to ]
            , cell [ textAlign center ] [ input [ type_ "checkbox", disabled True, checked rule.isRegex ] [] ]
            , cell [] [ text <| kindToString rule.kind ]
            , cell [ wordBreakAll ] [ text rule.why ]
            ]

        extraCols =
            if showAll then
                [ cell [] [ text rule.who ]
                , cell [] [ text <| dateToString <| rule.created ]
                , cell [] [ text <| dateToString <| rule.updated ]
                ]
            else
                []

        actionCols =
            [ cell [ minWidth <| px 250 ]
                [ button [ type_ "button", class "btn btn-link", onClick <| startEdit ] [ text "Edit" ]
                ]
            ]

        cols =
            primaryCols ++ extraCols ++ actionCols
    in
        tr [] cols


viewRuleEditRow : Bool -> msg -> (Rule -> msg) -> msg -> msg -> Rule -> Html msg
viewRuleEditRow showAll cancelEdit updateRule requestUpdateRule deleteRuleMsg rule =
    let
        updateFrom value =
            updateRule { rule | from = value }

        updateTo value =
            updateRule { rule | to = value }

        updateIsRegex =
            updateRule
                { rule | isRegex = not rule.isRegex }

        updateKind value =
            updateRule { rule | kind = (strToKind value) }

        updateWhy value =
            updateRule { rule | why = value }

        primaryCols =
            [ span [ styles cellStyles ] [ input [ value rule.from, onInput updateFrom, placeholder "From", styles [ Css.width <| pct 100 ] ] [] ]
            , span [ styles cellStyles ] [ input [ value rule.to, onInput updateTo, placeholder "To", styles [ Css.width <| pct 100 ] ] [] ]
            , span [ styles <| cellStyles ++ [ textAlign center ] ] [ input [ type_ "checkbox", onClick updateIsRegex, checked rule.isRegex ] [] ]
            , span [ styles cellStyles ]
                [ select [ class "form-control", onInput updateKind ]
                    [ option [ value << toString <| Permanent ] [ text <| kindToString Permanent ]
                    , option [ value << toString <| Temporary ] [ text <| kindToString Temporary ]
                    ]
                ]
            , span [ styles cellStyles ] [ input [ value rule.why, onInput updateWhy, placeholder "Why", styles [ Css.width <| pct 100 ] ] [] ]
            ]

        extraCols =
            if showAll then
                [ span [ styles cellStyles ] [ text rule.who ]
                , span [ styles cellStyles ] [ text <| dateToString <| rule.created ]
                , span [ styles cellStyles ] [ text <| dateToString <| rule.updated ]
                ]
            else
                []

        actionCols =
            [ span [ styles cellStyles ]
                [ button [ type_ "button", class "btn btn-success", styles [ marginRight (px 5) ], onClick requestUpdateRule ] [ text "Save" ]
                , button [ type_ "button", class "btn btn-outline-secondary", styles [ marginRight (px 5) ], onClick cancelEdit ] [ text "Cancel" ]
                , button [ type_ "button", class "btn btn-outline-danger", onClick deleteRuleMsg ] [ text "Delete" ]
                ]
            ]

        cols =
            primaryCols ++ extraCols ++ actionCols
    in
        Html.form [ styles [ display tableRow ], class "table-active", onSubmit requestUpdateRule ] cols


rulesDecoder : Decoder (List Rule)
rulesDecoder =
    Decode.list ruleDecoder


kindDecoder : Decoder Kind
kindDecoder =
    Decode.map strToKind Decode.string


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
        |> Json.Decode.Pipeline.required "kind" kindDecoder
        |> Json.Decode.Pipeline.required "why" Decode.string
        |> Json.Decode.Pipeline.required "who" Decode.string
        |> Json.Decode.Pipeline.required "isRegex" Decode.bool
        |> Json.Decode.Pipeline.required "created" dateDecoder
        |> Json.Decode.Pipeline.required "updated" dateDecoder


getRules : Http.Request (List Rule)
getRules =
    Http.get "/rules" rulesDecoder


addRule : MutationRule -> Http.Request Rule
addRule mutationRule =
    let
        jsonBody =
            Http.jsonBody <|
                Encode.object
                    [ ( "from", Encode.string mutationRule.from )
                    , ( "to", Encode.string mutationRule.to )
                    , ( "kind", Encode.string (toString mutationRule.kind) )
                    , ( "why", Encode.string mutationRule.why )
                    , ( "isRegex", Encode.bool mutationRule.isRegex )
                    ]
    in
        Http.post "/rules"
            jsonBody
            ruleDecoder


expectNothing : Http.Expect ()
expectNothing =
    Http.expectStringResponse (\_ -> Ok ())


updateRule : Rule -> Http.Request Rule
updateRule rule =
    let
        jsonBody =
            Http.jsonBody <|
                Encode.object
                    [ ( "from", Encode.string rule.from )
                    , ( "to", Encode.string rule.to )
                    , ( "kind", Encode.string (toString rule.kind) )
                    , ( "why", Encode.string rule.why )
                    , ( "isRegex", Encode.bool rule.isRegex )
                    ]
    in
        Http.request
            { method = "PUT"
            , headers = []
            , url = "/rules/" ++ (toString rule.ruleId)
            , body = jsonBody
            , expect = Http.expectJson ruleDecoder
            , timeout = Nothing
            , withCredentials = True
            }


deleteRule : RuleId -> Http.Request RuleId
deleteRule ruleId =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/rules/" ++ (toString ruleId)
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (\_ -> Ok ruleId)
        , timeout = Nothing
        , withCredentials = True
        }
