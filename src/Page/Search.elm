module Page.Search exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| Search Page or Workflow Instance listing
-}

import Api.NflowApi exposing (WorkflowDef, WorkflowSummary, searchWorkflows)
import Array
import Html exposing (Attribute, Html, button, div, input, option, select, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, onSubmit)
import Http
import Json.Decode as D
import Maybe exposing (andThen)
import Route exposing (SearchQueryParams, linkTo)
import Session exposing (Session)
import Util exposing (formatTime, spinner, textElem)


type alias Model =
    { session : Session
    , businessKey : String
    , externalId : String
    , workflowType : Maybe String
    , workflowState : Maybe String
    , workflowId : Maybe Int
    , parentWorkflowId : Maybe Int
    , searchResults : List WorkflowSummary
    , loading : Bool -- TODO replace with Maybe
    , workflowDefs : Maybe (List WorkflowDef)
    }


type Msg
    = GotSession Session
    | BusinessKeyChange String
    | ExternalIdChange String
    | WorkflowTypeChange (Maybe String)
    | WorkflowStateChange (Maybe String)
    | WorkflowIdChange (Maybe Int)
    | ParentWorkflowIdChange (Maybe Int)
    | Search
    | SearchResult (Result Http.Error (List WorkflowSummary))
    | WorkflowDefinitionResult (Result Http.Error (List WorkflowDef))


init : Session -> SearchQueryParams -> ( Model, Cmd Msg )
init session queryParams =
    let
        _ =
            Debug.log "init" queryParams.workflowType
    in
    ( { session = session
      , businessKey = Maybe.withDefault "" queryParams.businessKey
      , externalId = Maybe.withDefault "" queryParams.externalId
      , workflowType = queryParams.workflowType
      , workflowState = queryParams.workflowState
      , workflowId = String.toInt (Maybe.withDefault "" queryParams.workflowId)
      , parentWorkflowId = String.toInt (Maybe.withDefault "" queryParams.parentWorkflowId)
      , searchResults = []
      , loading = False
      , workflowDefs = Nothing
      }
    , Cmd.batch
        [ Api.NflowApi.fetchWorkflowDefs session.config WorkflowDefinitionResult
        ]
    )


toSession : Model -> Session
toSession model =
    model.session


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSession session ->
            ( { model | session = session }, Cmd.none )

        BusinessKeyChange value ->
            ( { model | businessKey = value }, Cmd.none )

        ExternalIdChange value ->
            ( { model | externalId = value }, Cmd.none )

        WorkflowTypeChange value ->
            let
                _ =
                    Debug.log "WorkflowTypeChange" value
            in
            ( { model | workflowType = value }, Cmd.none )

        WorkflowStateChange value ->
            let
                _ =
                    Debug.log "WorkflowStateChange" value
            in
            ( { model | workflowState = value }, Cmd.none )

        WorkflowIdChange value ->
            ( { model | workflowId = value }, Cmd.none )

        ParentWorkflowIdChange value ->
            ( { model | parentWorkflowId = value }, Cmd.none )

        Search ->
            ( { model
                | loading = True
              }
            , searchWorkflows model.session.config SearchResult
            )

        SearchResult (Ok workflowSummaries) ->
            ( { model
                | searchResults = workflowSummaries
                , loading = False
              }
            , Cmd.none
            )

        SearchResult (Err err) ->
            ( { model | loading = False }, Cmd.none )

        WorkflowDefinitionResult (Ok workflowDefs) ->
            ( { model | workflowDefs = Just workflowDefs }, Cmd.none )

        WorkflowDefinitionResult (Err err) ->
            ( { model | workflowDefs = Nothing }, Cmd.none )


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Workflow instances"
    , content =
        div []
            -- Search msg must be either in form onSubmit or searchButton onClick
            -- but not both
            [ Html.form [ onSubmit Search ]
                [ dropDown model.workflowType (workflowTypeEntries model "-- All workflow types --") "Workflow type" WorkflowTypeChange
                , dropDown model.workflowState (workflowStateEntries model "-- All workflow states --") "Workflow states" WorkflowStateChange
                , textField model.businessKey "Business Key" BusinessKeyChange
                , textField model.externalId "External id" ExternalIdChange
                , integerField model.workflowId "Workflow id" WorkflowIdChange
                , integerField model.parentWorkflowId "Parent workflow id" ParentWorkflowIdChange
                , searchButton model
                ]
            , if model.loading then
                spinner

              else
                case model.searchResults of
                    [] ->
                        text "No results"

                    results ->
                        searchResultsTable results
            ]
    }


workflowTypeEntries : Model -> String -> List Entry
workflowTypeEntries model defaultTitle =
    case model.workflowDefs of
        Just workflowDefList ->
            [ { key = "", value = defaultTitle } ]
                ++ List.map (\w -> { key = w.definitionType, value = w.definitionType }) workflowDefList

        Nothing ->
            [ { key = "", value = defaultTitle } ]


workflowStateEntries : Model -> String -> List Entry
workflowStateEntries model defaultTitle =
    case ( model.workflowType, model.workflowDefs ) of
        ( Just workflowType, Just workflowDefList ) ->
            let
                l =
                    List.head (List.filter (\w -> w.definitionType == workflowType) workflowDefList)

                entries =
                    case l of
                        Nothing ->
                            []

                        Just workflowDef ->
                            List.map (\x -> { key = x.id, value = x.id }) workflowDef.states
            in
            [ { key = "", value = defaultTitle } ] ++ entries

        ( _, _ ) ->
            [ { key = "", value = defaultTitle } ]


searchResultsTable : List WorkflowSummary -> Html Msg
searchResultsTable workflowSummaries =
    div []
        [ table [ class "pure-table" ]
            [ thead []
                [ th [] [ text "Id" ]
                , th [] [ text "Workflow type" ]
                , th [] [ text "State" ]
                , th [] [ text "State text" ]
                , th [] [ text "Status" ]
                , th [] [ text "Business key" ]
                , th [] [ text "External id" ]
                , th [] [ text "Retries" ]
                , th [] [ text "Created" ]
                , th [] [ text "Started" ]
                , th [] [ text "Modified" ]
                , th [] [ text "Next activation" ]
                ]
            , tbody []
                (List.map workflowSummaryRow workflowSummaries)
            ]
        ]


workflowSummaryRow : WorkflowSummary -> Html msg
workflowSummaryRow workflow =
    tr []
        [ td [] [ linkTo (Route.InstanceDetails workflow.id) [ text (String.fromInt workflow.id) ] ]
        , td [] [ linkTo (Route.InstanceDetails workflow.id) [ text workflow.workflowType ] ]
        , td [] [ text workflow.state ]
        , td [] [ text workflow.stateText ]
        , td [] [ text workflow.status ]
        , td [] [ textElem workflow.businessKey ]
        , td [] [ text workflow.externalId ]
        , td [] [ text (String.fromInt workflow.retries) ]
        , td [] [ text (formatTime workflow.created) ]
        , td [] [ textElem (Maybe.map formatTime workflow.started) ]
        , td [] [ text (formatTime workflow.modified) ]
        , td [] [ textElem (Maybe.map formatTime workflow.nextActivation) ]
        ]


textField : String -> String -> (String -> Msg) -> Html Msg
textField fieldValue title changeMsg =
    div []
        [ input
            [ value fieldValue
            , placeholder title
            , onInput changeMsg
            ]
            []
        ]


integerField : Maybe Int -> String -> (Maybe Int -> Msg) -> Html Msg
integerField fieldValue title changeMsg =
    let
        parseInt : String -> Maybe Int
        parseInt s =
            String.toInt s

        v =
            case fieldValue of
                Just x ->
                    String.fromInt x

                _ ->
                    ""
    in
    div []
        [ input
            [ value v
            , placeholder title
            , type_ "number"
            , onInput (\x -> changeMsg (parseInt x))
            ]
            []
        ]


searchButton : Model -> Html Msg
searchButton model =
    div []
        [ button [] [ text "Search" ]
        ]

{-|
  DropDowns.
-}

type alias Entry =
    { key : String, value : String }


dropDown : Maybe String -> List Entry -> String -> (Maybe String -> msg) -> Html msg
dropDown maybeSelected entries title msg =
    select [ onInput (\x -> msg (val x)) ]
        (List.map (\entry -> dropDownOption maybeSelected entry msg) entries)


val : String -> Maybe String
val value =
    case value of
        "" ->
            Nothing

        x ->
            Just x


dropDownOption : Maybe String -> Entry -> (Maybe String -> msg) -> Html msg
dropDownOption maybeSelected entry msg =
    let
        isSelected =
            case maybeSelected of
                Just selectedKey ->
                    selectedKey == entry.key

                Nothing ->
                    False
    in
    option [ value entry.key, selected isSelected ] [ text entry.value ]
