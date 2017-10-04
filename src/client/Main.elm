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
    , ruleToEdit : Maybe RuleId
    , ruleToEditIsValid : Bool
    , ruleToAdd : MutationRule
    , ruleToAddIsValid : Bool
    , showAddRule : Bool
    , flash : Maybe Flash
    }


type Msg
    = SortByColumn Column
    | EditRule (Maybe RuleId)
    | FetchedRules (Result Http.Error (List Rule))
    | RequestAddRule MutationRule
    | CancelAddRule
    | SetShowAddRule Bool
    | UpdateAddRule MutationRule
    | ResultAddRule (Result Http.Error Rule)
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
    in
        case msg of
            SortByColumn column ->
                if column == model.sortColumn then
                    ( { model | sortDirection = reverseDirection }, Cmd.none )
                else
                    ( { model | sortColumn = column, sortDirection = Ascending }, Cmd.none )

            EditRule ruleId ->
                ( { model | ruleToEdit = ruleId }, Cmd.none )

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

            HideFlash ->
                ( { model | flash = Nothing }, Cmd.none )



-- Todo empty input fields here


viewRuleTable : Model -> List (Html Msg) -> Html Msg
viewRuleTable model initialRows =
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
            (Maybe.withDefault False (model.ruleToEdit |> Maybe.map (\ruleToEdit -> ruleToEdit == rule.ruleId)))

        ruleRows =
            model.rules
                |> sortByColumn model.sortColumn model.sortDirection
                |> List.map
                    (\rule -> ruleToRow (shouldBeEditable rule) (EditRule (Just rule.ruleId)) (EditRule Nothing) rule)
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
            , tbody [] (initialRows ++ ruleRows)
            ]


view : Model -> Html Msg
view model =
    let
        editRows =
            if model.showAddRule then
                [ viewAddRuleRow CancelAddRule RequestAddRule UpdateAddRule model.ruleToAdd ]
            else
                []
    in
        div []
            [ viewMaybeFlash model.flash
            , button [ onClick (SetShowAddRule (not model.showAddRule)) ] [ text "Add" ]
            , viewRuleTable model editRows
            ]


init : ( Model, Cmd Msg )
init =
    ( { rules = []
      , sortColumn = From
      , sortDirection = Ascending
      , ruleToEdit = Nothing
      , ruleToEditIsValid = False
      , ruleToAdd = MutationRule "" "" Temporary "" "" False
      , ruleToAddIsValid = False
      , showAddRule = True
      , flash = Nothing
      }
    , Cmd.batch
        [ Http.send FetchedRules getRules
        ]
    )
