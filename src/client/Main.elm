module Main exposing (..)

import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Date exposing (Date)
import Date.Extra.Format as Format exposing (format)
import Date.Extra.Config.Config_en_us exposing (config)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline
import Rule exposing (..)
import Flash exposing (..)
import Time
import Task
import Process


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type Column
    = From
    | To
    | IsRegex
    | Variety
    | Why
    | Who
    | Created
    | Updated


type alias Model =
    { rules : List Rule
    , sortColumn : Column
    , sortDirection : Direction
    , ruleToEdit : Rule
    , ruleToEditIsValid : Bool
    , ruleToAdd : MutationRule
    , ruleToAddIsValid : Bool
    , showAddRule : Bool
    , flash : Maybe Flash
    }


type Msg
    = SortByColumn Column
    | EditRule Rule
    | UpdateEditRule Rule
    | ResultUpdateRule (Result Http.Error Rule)
    | RequestUpdateRule
    | FetchedRules (Result Http.Error (List Rule))
    | RequestAddRule MutationRule
    | CancelAddRule
    | SetShowAddRule Bool
    | UpdateAddRule MutationRule
    | ResultAddRule (Result Http.Error Rule)
    | RequestDeleteRule RuleId
    | ResultDeleteRule (Result Http.Error Rule)
    | HideFlash


type Direction
    = Ascending
    | Descending


delay : Time.Time -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)


setFlash : Model -> Flash -> ( Model, Cmd Msg )
setFlash model flash =
    { model | flash = Just flash } ! [ delay (Time.second * 5) HideFlash ]


humanReadableRuleValidationError : RuleValidationError -> String
humanReadableRuleValidationError error =
    case error of
        FromIsEmpty ->
            "Please specify which path(s) should be redirected."

        ToIsEmpty ->
            "Please specify where the request should be routed."

        ToIsNotAUri ->
            "\"To\" needs to be a valid path or URI e.g \"/gb/help\", \"http://izettle.com/gb\"."

        FromIsNotAPath ->
            "\"From\" needs to be a valid path e.g \"/gb/help\"."

        WhyIsEmpty ->
            "Please record why the rule is needed, for posterity."

        WhyIsTooShort ->
            "Please elaborate on the purpose of the rule."


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

                IsRegex ->
                    .isRegex >> toString

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

        allRulesBut ruleId =
            model.rules |> List.filter (.ruleId >> (/=) ruleId)
    in
        case msg of
            SortByColumn column ->
                if column == model.sortColumn then
                    ( { model | sortDirection = reverseDirection }, Cmd.none )
                else
                    ( { model | sortColumn = column, sortDirection = Ascending }, Cmd.none )

            EditRule rule ->
                ( { model | ruleToEdit = rule }, Cmd.none )

            UpdateEditRule rule ->
                ( { model | ruleToEdit = rule }, Cmd.none )

            RequestUpdateRule ->
                -- todo add validation
                --                case validateRule model.rule of
                --                    Ok rule ->
                ( model
                , Http.send ResultUpdateRule (updateRule model.ruleToEdit)
                )

            --                    Err errorType ->
            --                        setFlash model <| Warn (humanReadableRuleValidationError errorType)
            FetchedRules (Err error) ->
                Debug.crash (toString error)

            FetchedRules (Ok rules) ->
                ( { model | rules = rules }, Cmd.none )

            RequestAddRule rule ->
                case validateRule rule of
                    Ok rule ->
                        ( model
                        , Http.send ResultAddRule <| addRule rule
                        )

                    Err errorType ->
                        setFlash model <| Warn (humanReadableRuleValidationError errorType)

            CancelAddRule ->
                ( { model | showAddRule = False }, Cmd.none )

            SetShowAddRule value ->
                ( { model | showAddRule = value }, Cmd.none )

            UpdateAddRule mutationRule ->
                ( { model | ruleToAdd = mutationRule }, Cmd.none )

            ResultAddRule result ->
                case result of
                    Err msg ->
                        setFlash model <| Error "Error adding rule."

                    Ok rule ->
                        setFlash
                            { model
                                | rules = rule :: model.rules
                                , ruleToAdd = MutationRule "" "" Temporary "" "" False
                                , showAddRule = False
                            }
                            (Success <| "Added rule for \"" ++ rule.from ++ "\"")

            ResultUpdateRule result ->
                case result of
                    Err msg ->
                        setFlash model <| Error "Error updating rule."

                    Ok rule ->
                        setFlash
                            { model
                                | rules = rule :: (allRulesBut rule.ruleId)
                                , ruleToEdit = emptyRule
                            }
                            (Success <| "Updated rule for \"" ++ rule.from ++ "\"")

            RequestDeleteRule ruleId ->
                ( model, Http.send ResultDeleteRule <| deleteRule ruleId )

            ResultDeleteRule result ->
                case result of
                    Err msg ->
                        setFlash model <| Error "Error deleting rule."

                    Ok rule ->
                        setFlash { model | rules = allRulesBut rule.ruleId } <| Success "Rule deleted."

            HideFlash ->
                ( { model | flash = Nothing }, Cmd.none )



-- Todo empty input fields here


viewRuleTable : Model -> List (Html Msg) -> Html Msg
viewRuleTable model addRuleRows =
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

        shouldBeEditable rule =
            model.ruleToEdit.ruleId == rule.ruleId

        getRule rule =
            if shouldBeEditable rule then
                model.ruleToEdit
            else
                rule

        ruleToRow rule =
            if shouldBeEditable rule then
                viewRuleEditRow (EditRule emptyRule) UpdateEditRule RequestUpdateRule (RequestDeleteRule rule.ruleId) model.ruleToEdit
            else
                viewRuleRow (EditRule rule) rule

        ruleRows =
            model.rules
                |> sortByColumn model.sortColumn model.sortDirection
                |> List.map ruleToRow
    in
        table [ class "table" ]
            [ thead []
                [ tr []
                    [ th [ onClick <| SortByColumn From ] [ text <| "From" ++ showArrow From ]
                    , th [ onClick <| SortByColumn To ] [ text <| "To" ++ showArrow To ]
                    , th [ onClick <| SortByColumn IsRegex ] [ text <| "Pattern" ++ showArrow IsRegex ]
                    , th [ onClick <| SortByColumn Variety ] [ text <| "Variety" ++ showArrow Variety ]
                    , th [ onClick <| SortByColumn Why ] [ text <| "Why" ++ showArrow Why ]
                    , th [ onClick <| SortByColumn Who ] [ text <| "Who" ++ showArrow Who ]
                    , th [ onClick <| SortByColumn Created ] [ text <| "Created" ++ showArrow Created ]
                    , th [ onClick <| SortByColumn Updated ] [ text <| "Updated" ++ showArrow Updated ]
                    , th [] [ text "Actions" ]
                    ]
                ]
            , tbody [] (addRuleRows ++ ruleRows)
            ]


view : Model -> Html Msg
view model =
    let
        addRuleRows =
            if model.showAddRule then
                [ viewAddRuleRow CancelAddRule RequestAddRule UpdateAddRule model.ruleToAdd ]
            else
                []
    in
        div []
            [ viewMaybeFlash model.flash
            , button [ onClick (SetShowAddRule (not model.showAddRule)) ] [ text "Add" ]
            , viewRuleTable model addRuleRows
            ]


emptyRule : Rule
emptyRule =
    Rule -1 "" "" Temporary "" "" False (Date.fromTime 0) (Date.fromTime 0)


init : ( Model, Cmd Msg )
init =
    ( { rules = []
      , sortColumn = From
      , sortDirection = Ascending
      , ruleToEdit = emptyRule
      , ruleToEditIsValid = False
      , ruleToAdd = MutationRule "" "" Temporary "" "" False
      , ruleToAddIsValid = False
      , showAddRule = False
      , flash = Nothing
      }
    , Cmd.batch
        [ Http.send FetchedRules getRules
        ]
    )
