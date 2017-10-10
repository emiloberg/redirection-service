module Main exposing (..)

import Http exposing (Error(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Date exposing (Date)
import Rule exposing (..)
import Flash exposing (..)
import Time
import Task
import Process
import Header exposing (header)
import Column exposing (..)
import Util exposing (styles, anyListMember, removeFromList)
import Maybe exposing (withDefault)
import Dict exposing (..)
import String exposing (contains)
import List exposing (drop)
import Modal exposing (viewHelpModal, viewHelpButton)
import Css
    exposing
        ( px
        , padding
        , marginBottom
        , displayFlex
        , flexDirection
        , column
        , alignItems
        , center
        , flexEnd
        , padding2
        , justifyContent
        , spaceBetween
        , textAlign
        , center
        , marginLeft
        )


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


extendedColumns : List Column
extendedColumns =
    [ Who, Created, Updated ]


type alias Model =
    { rules : List Rule
    , sortColumn : Column
    , sortDirection : Direction
    , ruleToEdit : Rule
    , ruleToAdd : MutationRule
    , ruleToAddIsValid : Bool
    , showAddRule : Bool
    , flash : List Flash
    , filterText : Maybe String
    , displayColumns : List Column
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
    | ResultDeleteRule (Result Http.Error RuleId)
    | HideFlash
    | UpdateFilter String
    | ToggleShowExtendedCols
    | ToggleExpertMode


type Direction
    = Ascending
    | Descending


delay : Time.Time -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.perform (\_ -> msg)


setFlash : Model -> Flash -> ( Model, Cmd Msg )
setFlash model flash =
    ( { model | flash = model.flash ++ [ flash ] }, delay (Time.second * 5) HideFlash )


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

                Kind ->
                    .kind >> toString

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


handleError : Model -> Http.Error -> ( Model, Cmd Msg )
handleError model error =
    case error of
        BadUrl msg ->
            setFlash model <| Error "The requested resource does not exist."

        Timeout ->
            setFlash model <| Error "The server took too long to answer."

        NetworkError ->
            setFlash model <| Error "The network is inaccessible."

        BadStatus response ->
            if String.isEmpty response.body then
                setFlash model <| Error <| "Unable to complete operation."
            else
                setFlash model <| Error response.body

        BadPayload msg response ->
            setFlash model <| Error <| "Operation successful, but the response is malformed: " ++ response.body ++ "."


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
                ( model, Http.send ResultUpdateRule (updateRule model.ruleToEdit) )

            FetchedRules (Err error) ->
                Debug.crash (toString error)

            FetchedRules (Ok rules) ->
                ( { model | rules = rules }, Cmd.none )

            RequestAddRule rule ->
                ( model, Http.send ResultAddRule <| addRule rule )

            CancelAddRule ->
                ( { model | showAddRule = False }, Cmd.none )

            SetShowAddRule value ->
                ( { model | showAddRule = value }, Cmd.none )

            UpdateAddRule mutationRule ->
                ( { model | ruleToAdd = mutationRule }, Cmd.none )

            ResultAddRule result ->
                case result of
                    Err error ->
                        handleError model error

                    Ok rule ->
                        setFlash
                            { model
                                | rules = rule :: model.rules
                                , ruleToAdd = MutationRule "" "" Permanent "" "" False
                                , showAddRule = False
                            }
                            (Success <| "Added rule for \"" ++ rule.from ++ "\"")

            ResultUpdateRule result ->
                case result of
                    Err error ->
                        handleError model error

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
                    Err error ->
                        handleError model error

                    Ok ruleId ->
                        setFlash { model | rules = allRulesBut ruleId } <| Success "Rule deleted."

            HideFlash ->
                ( { model | flash = drop 1 model.flash }, Cmd.none )

            UpdateFilter "" ->
                ( { model | filterText = Nothing }, Cmd.none )

            UpdateFilter text ->
                ( { model | filterText = Just text }, Cmd.none )

            ToggleExpertMode ->
                let
                    isShowingextendedColumns =
                        anyListMember extendedColumns model.displayColumns

                    columnsWithoutextendedColumns =
                        removeFromList extendedColumns model.displayColumns

                    columns =
                        if List.member IsRegex model.displayColumns then
                            removeFromList [ IsRegex ] model.displayColumns
                        else if isShowingextendedColumns then
                            columnsWithoutextendedColumns ++ [ IsRegex ] ++ extendedColumns
                        else
                            columnsWithoutextendedColumns ++ [ IsRegex ]
                in
                    ( { model | displayColumns = columns }, Cmd.none )

            ToggleShowExtendedCols ->
                let
                    columns =
                        if anyListMember extendedColumns model.displayColumns then
                            removeFromList extendedColumns model.displayColumns
                        else
                            model.displayColumns ++ extendedColumns
                in
                    ( { model | displayColumns = columns }, Cmd.none )


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
                viewRuleEditRow model.displayColumns (EditRule emptyRule) UpdateEditRule RequestUpdateRule (RequestDeleteRule rule.ruleId) model.ruleToEdit
            else
                viewRuleRow model.displayColumns (EditRule rule) rule

        filteredRules =
            case model.filterText of
                Nothing ->
                    model.rules

                Just text ->
                    List.filter (\rule -> contains text rule.from || contains text rule.to) model.rules

        ruleRows =
            filteredRules
                |> sortByColumn model.sortColumn model.sortDirection
                |> List.map ruleToRow

        cells =
            Dict.fromList
                [ ( toString From, th [ onClick <| SortByColumn From ] [ text <| "From" ++ showArrow From ] )
                , ( toString To, th [ onClick <| SortByColumn To ] [ text <| "To" ++ showArrow To ] )
                , ( toString IsRegex, th [ onClick <| SortByColumn IsRegex, styles [ textAlign center ] ] [ text <| "Pattern" ++ showArrow IsRegex ] )
                , ( toString Kind, th [ onClick <| SortByColumn Kind ] [ text <| "Kind" ++ showArrow Kind ] )
                , ( toString Why, th [ onClick <| SortByColumn Why ] [ text <| "Why" ++ showArrow Why ] )
                , ( toString Who, th [ onClick <| SortByColumn Who ] [ text <| "Who" ++ showArrow Who ] )
                , ( toString Created, th [ onClick <| SortByColumn Created ] [ text <| "Created" ++ showArrow Created ] )
                , ( toString Updated, th [ onClick <| SortByColumn Updated ] [ text <| "Updated" ++ showArrow Updated ] )
                ]

        cols =
            model.displayColumns
                |> List.map (\col -> Maybe.withDefault (text "") (Dict.get (toString col) cells))
    in
        table [ class "table" ]
            [ thead [] [ tr [] (cols ++ [ th [] [ text "Actions" ] ]) ]
            , tbody [] (addRuleRows ++ ruleRows)
            ]


view : Model -> Html Msg
view model =
    let
        addRuleRows =
            if model.showAddRule then
                [ viewAddRuleRow model.displayColumns CancelAddRule RequestAddRule UpdateAddRule model.ruleToAdd ]
            else
                []

        layout children =
            div []
                [ viewHelpModal
                , viewFlashes model.flash
                , Header.header
                , div [ styles [ padding <| px 20, displayFlex, flexDirection column ] ] children
                ]

        notice =
            div [ class "jumbotron", styles [ padding2 (Css.rem 2) (Css.rem 1), marginBottom (px 20) ] ]
                [ p [ class "lead" ]
                    [ text "This service allow redirecting incoming traffic to izettle.com to any other path or url on the web." ]
                , p [] [ text "Note that any changes can take up to 10 minutes until taking effect." ]
                , viewHelpButton
                ]

        newButton =
            button [ class "btn btn-primary", styles [ marginBottom (px 10) ], onClick (SetShowAddRule (not model.showAddRule)) ]

        updateFilterText value =
            { model | filterText = value }

        shouldShowExtendedCols =
            anyListMember extendedColumns model.displayColumns

        isExpertMode =
            List.member IsRegex model.displayColumns

        actionBar =
            div []
                [ label []
                    [ text "Show all columns:"
                    , input [ type_ "checkbox", checked shouldShowExtendedCols, styles [ marginLeft <| px 5 ], onClick ToggleShowExtendedCols ] []
                    , text "Expert mode:"
                    , input [ type_ "checkbox", checked isExpertMode, styles [ marginLeft <| px 5 ], onClick ToggleExpertMode ] []
                    ]
                , div
                    [ styles [ displayFlex, justifyContent spaceBetween, alignItems center ] ]
                    [ input [ value <| withDefault "" model.filterText, placeholder "Filter", autofocus True, onInput UpdateFilter ] []
                    , newButton [ text "＋" ]
                    ]
                ]
    in
        layout
            [ notice
            , actionBar
            , viewRuleTable model addRuleRows
            ]


emptyRule : Rule
emptyRule =
    Rule -1 "" "" Temporary "" "" False (Date.fromTime 0) (Date.fromTime 0)


emptyMutationRule : MutationRule
emptyMutationRule =
    MutationRule "" "" Permanent "" "" False


init : ( Model, Cmd Msg )
init =
    ( { rules = []
      , sortColumn = From
      , sortDirection = Ascending
      , ruleToEdit = emptyRule
      , ruleToAdd = emptyMutationRule
      , ruleToAddIsValid = False
      , showAddRule = False
      , flash = []
      , filterText = Nothing
      , displayColumns = [ From, To, Kind, Why ]
      }
    , Cmd.batch
        [ Http.send FetchedRules getRules
        ]
    )
