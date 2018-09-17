module Page.DefinitionList exposing (Msg, Model, view, init, update, toSession, subscriptions)

{-|
Executors list
-}
import Api.NflowApi exposing (WorkflowDef, fetchWorkflowDefs)
import Html exposing (Html, table, th, tr, td, tbody, thead, text, div)
import Session exposing (Session)
import Http
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder, src)
import Time exposing (Posix)

type alias Model =
    { session: Session
    , loading: Bool
    , workflowDefs: List WorkflowDef
    , message: String
    }

type Msg
    = LoadResult (Result Http.Error (List WorkflowDef))
    | Error
    | GotSession Session

init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , loading = True
      , workflowDefs = []
      , message = ""}
    , fetchWorkflowDefs LoadResult
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
      LoadResult (Ok workflowDefs) ->
         ( { model | workflowDefs = workflowDefs
                   , loading = False }, Cmd.none )

      LoadResult (Err err) ->
         ( { model | message = (Debug.toString err)
                   , workflowDefs = []
                   , loading = False }, Cmd.none )

      _ -> (model, Cmd.none)


-- TODO move to util
formatTime: String -> String
formatTime time =
    time

workflowDefRow: WorkflowDef -> Html msg
workflowDefRow workflowDef =
  tr []
    [ (td [] [text workflowDef.definitionType] )
    , (td []
         (case workflowDef.description of
           Just x ->
             [text x]
           Nothing -> [text "No description"]
         )
       )
    ]

workflowDefsTable: List WorkflowDef -> List (Html msg)
workflowDefsTable workflowDefs =
    [table [ class "pure-table" ]
      [ thead []
        [ (th [] [text "Type"])
        , (th [] [text "Description"])
        ]
      , tbody []
        (List.map workflowDefRow workflowDefs)
      ]
    ]

view : Model -> { title : String, content : Html msg }
view model =
    { title = "Workflow Definitions"
    , content = div [] (
      if model.loading then
        -- TODO show spinner
        -- TODO show load failed error
        [text "loading"]
      else
         let
           _ = Debug.log "xxx" model
         in
        workflowDefsTable model.workflowDefs
    )
    }
