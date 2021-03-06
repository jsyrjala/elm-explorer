port module Page.InstanceDetails exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| Workflow instance details
-}

import Api.NflowApi exposing (Action, WorkflowSummary, getWorkflowDetails)
import Html exposing (Html, div, h2, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, href, id, style)
import Http
import Json.Decode as D
import Json.Encode as E
import Route exposing (linkTo)
import Session exposing (Session)
import Svg
import Svg.Attributes as SvgA
import Util exposing (textElem)



-- https://guide.elm-lang.org/interop/ports.html


port instanceStateSelectedIn : (E.Value -> msg) -> Sub msg


port drawInstanceGraph : E.Value -> Cmd msg


type alias Model =
    { session : Session
    , id : Int
    , loading : Bool
    , workflow : Maybe WorkflowSummary
    , selectedState : Maybe String
    }


type Msg
    = GotSession Session
    | LoadResult (Result Http.Error WorkflowSummary)
    | StateSelected E.Value


toSession : Model -> Session
toSession model =
    model.session


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ instanceStateSelectedIn StateSelected
        , Session.changes GotSession (Session.navKey model.session)
        ]


init : Session -> Int -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , id = id
      , loading = True
      , workflow = Nothing
      , selectedState = Nothing
      }
    , getWorkflowDetails session.config id LoadResult
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSession session ->
            ( { model | session = session }, Cmd.none )

        LoadResult (Ok workflow) ->
            ( { model
                | workflow = Just workflow
                , loading = False
              }
            , drawInstanceGraph (E.string "TODO")
            )

        LoadResult (Err err) ->
            ( { model
                | workflow = Nothing
                , loading = False
              }
            , Cmd.none
            )

        StateSelected value ->
            case D.decodeValue D.string value of
                Result.Ok state ->
                    ( { model | selectedState = Just state }, Cmd.none )

                Result.Err _ ->
                    ( model, Cmd.none )


view : Model -> { title : String, content : Html msg }
view model =
    { title = "Workflow Instance"
    , content =
        case model.workflow of
            Just workflow ->
                div []
                    [ dataTable model workflow
                    , graph model workflow
                    , actionHistory model workflow
                    ]

            Nothing ->
                div []
                    [ text "Not found"
                    ]
    }


dataTable : Model -> WorkflowSummary -> Html msg
dataTable model workflow =
    div []
        [ h2 [] [ text workflow.workflowType ]
        , linkTo (Route.DefinitionDetails workflow.workflowType) [ text "Go to workflow definition" ]
        , text "Parent workflow:"
        , text "Created:"
        , text workflow.created
        , text "Started:"
        , textElem workflow.started
        , text "Modified:"
        , text workflow.modified
        , text "Current state:"
        , text (workflow.state ++ " (" ++ workflow.stateText ++ ")")
        , text "Current status:"
        , text workflow.status
        , text "Next activation:"
        , textElem workflow.started
        , text "Workflow id"
        , text (String.fromInt workflow.id)
        , text "Business key"
        , textElem workflow.businessKey
        , text "External id"
        , text workflow.externalId
        ]


graph : Model -> WorkflowSummary -> Html msg
graph model workflow =
    div [ class "svg-container" ]
        [ Svg.svg [ id "instance-graph" ] []
        ]


actionHistory : Model -> WorkflowSummary -> Html msg
actionHistory model workflow =
    case workflow.actions of
        Just actions ->
            div []
                [ h2 [] [ text "Action history" ]
                , table [ class "pure-table workflow-actions" ]
                    [ thead []
                        [ tr []
                            [ th [] [ text "No" ]
                            , th [] [ text "State" ]
                            , th [] [ text "Description" ]
                            , th [] [ text "Retries" ]
                            , th [] [ text "Started" ]
                            , th [] [ text "Finished" ]
                            , th [] [ text "Duration" ]
                            ]
                        ]
                    , tbody []
                        (let
                            row index action =
                                actionHistoryRow model (List.length actions - index) action
                         in
                         List.indexedMap row actions
                        )
                    ]
                ]

        Nothing ->
            text "No actions"


actionHistoryRow : Model -> Int -> Action -> Html msg
actionHistoryRow model index action =
    let
        className =
            case model.selectedState of
                Nothing ->
                    "unselected"

                Just state ->
                    if state == action.state then
                        "selected"

                    else
                        "unselected"
    in
    tr [ class className ]
        [ td [] [ text (String.fromInt index) ]
        , td [] [ text action.state ]
        , td [] [ text action.stateText ]
        , td [] [ text (String.fromInt action.retryNo) ]
        , td [] [ text action.executionStartTime ]
        , td [] [ textElem action.executionEndTime ]
        , td [] [ text "XXX" ] -- TODO compute duration
        ]


stateVariables : Model -> WorkflowSummary -> Html msg
stateVariables model workflow =
    div []
        [ h2 [] [ text "State variable go here" ]
        ]


manage : model -> WorkflowSummary -> Html msg
manage model workflow =
    div []
        [ h2 [] [ text "Manage" ]
        ]
