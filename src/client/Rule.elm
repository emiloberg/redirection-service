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
import Debug
import Result exposing (andThen)
import Regex exposing (contains, regex)
import List exposing (foldl)
import Css exposing (display, tableRow, tableCell, backgroundColor, hex, solid, px, borderTop3, top, verticalAlign, padding, marginRight)
import Css.Colors exposing (teal, yellow)
import Util exposing (styles)


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


cellStyles =
    [ display tableCell, padding (Css.rem 0.75), verticalAlign top, borderTop3 (px 1) solid (hex "e9ecef") ]


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


type RuleValidationError
    = FromIsEmpty
    | FromIsNotAPath
    | ToIsEmpty
    | ToIsNotAUri
    | WhyIsEmpty
    | WhyIsTooShort


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

        isUrl =
            contains <| regex "(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"

        oneOf validators value =
            let
                validations =
                    List.map ((|>) value) validators
            in
                foldl (||) False validations

        isShort str =
            String.length str < 20
    in
        Ok rule
            |> andThen (validate FromIsEmpty (.from >> String.isEmpty >> not))
            |> andThen (validate FromIsNotAPath (oneOf [ .from >> isPath, .isRegex ]))
            |> andThen (validate ToIsEmpty (.to >> String.isEmpty >> not))
            |> andThen (validate ToIsNotAUri (oneOf [ .to >> isPath, .to >> isUrl, .isRegex ]))
            |> andThen (validate WhyIsEmpty (.why >> String.isEmpty >> not))
            |> andThen (validate WhyIsTooShort (.why >> isShort >> not))


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
        Html.form [ styles [ display tableRow ], class "table-active", onSubmit <| saveMessage rule ]
            [ span [ styles cellStyles ] [ input [ value rule.from, placeholder "From", onInput updateFrom ] [] ]
            , span [ styles cellStyles ] [ input [ value rule.to, placeholder "To", onInput updateTo ] [] ]
            , span [ styles cellStyles ] [ input [ type_ "checkbox", checked rule.isRegex, onClick updateIsRegex ] [] ]
            , span [ styles cellStyles ]
                [ select [ class "form-control", onInput updateVariety ]
                    [ option [ value << toString <| Permanent, (selected (rule.variety == Permanent)) ] [ text << toString <| Permanent ]
                    , option [ value << toString <| Temporary, (selected (rule.variety == Temporary)) ] [ text << toString <| Temporary ]
                    ]
                ]
            , span [ styles cellStyles ] [ input [ value rule.why, placeholder "Why", onInput updateWhy ] [] ]
            , span [ styles cellStyles ] []
            , span [ styles cellStyles ] []
            , span [ styles cellStyles ] []
            , span [ styles cellStyles ]
                [ a [ href "#", class "btn btn-success", styles [ marginRight (px 5) ], onClick <| saveMessage rule ] [ text "Save" ]
                , a [ href "#", class "btn btn-outline-secondary", onClick <| cancelMessage ] [ text "Cancel" ]
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
            [ button [ class "btn btn-link", onClick <| startEdit ] [ text "Edit" ]
            ]
        ]


viewRuleEditRow : msg -> (Rule -> msg) -> msg -> msg -> Rule -> Html msg
viewRuleEditRow cancelEdit updateRule requestUpdateRule deleteRuleMsg rule =
    let
        updateFrom value =
            updateRule { rule | from = value }

        updateTo value =
            updateRule { rule | to = value }

        updateIsRegex =
            updateRule
                { rule | isRegex = not rule.isRegex }

        updateVariety value =
            updateRule { rule | variety = (strToVariety value) }

        updateWhy value =
            updateRule { rule | why = value }
    in
        Html.form [ styles [ display tableRow ], class "table-active", onSubmit requestUpdateRule ]
            [ span [ styles cellStyles ] [ input [ value rule.from, placeholder "From" ] [] ]
            , span [ styles cellStyles ] [ input [ value rule.to, placeholder "To" ] [] ]
            , span [ styles cellStyles ] [ input [ type_ "checkbox", checked rule.isRegex ] [] ]
            , span [ styles cellStyles ]
                [ select [ class "form-control" ]
                    [ option [ value << toString <| Permanent ] [ text << toString <| Permanent ]
                    , option [ value << toString <| Temporary ] [ text << toString <| Temporary ]
                    ]
                ]
            , span [ styles cellStyles ] [ input [ value rule.why, placeholder "Why" ] [] ]
            , span [ styles cellStyles ] [ text rule.who ]
            , span [ styles cellStyles ] [ text <| dateToString <| rule.created ]
            , span [ styles cellStyles ] [ text <| dateToString <| rule.updated ]
            , span [ styles cellStyles ]
                [ a [ href "#", class "btn btn-success", styles [ marginRight (px 5) ], onClick <| requestUpdateRule ] [ text "Save" ]
                , a [ href "#", class "btn btn-outline-secondary", styles [ marginRight (px 5) ], onClick <| cancelEdit ] [ text "Cancel" ]
                , a [ href "#", class "btn btn-outline-danger", onClick <| deleteRuleMsg ] [ text "Delete" ]
                ]
            ]


rulesDecoder : Decoder (List Rule)
rulesDecoder =
    Decode.list ruleDecoder


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
    Http.get "/rules" rulesDecoder


addRule : MutationRule -> Http.Request Rule
addRule mutationRule =
    let
        jsonBody =
            Http.jsonBody <|
                Encode.object
                    [ ( "from", Encode.string mutationRule.from )
                    , ( "to", Encode.string mutationRule.to )
                    , ( "kind", Encode.string (toString mutationRule.variety) )
                    , ( "why", Encode.string mutationRule.why )
                    , ( "isRegex", Encode.bool mutationRule.isRegex )
                    ]
    in
        Http.post "/rules"
            jsonBody
            ruleDecoder


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
                    , ( "kind", Encode.string (toString rule.variety) )
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
