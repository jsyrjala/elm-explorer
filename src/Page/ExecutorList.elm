module Page.ExecutorList exposing (Msg, Model, view, init, update, toSession)

{-|
Executors list
-}
import Api.NflowApi exposing (Executor, fetchExecutors)
import Html exposing (Html, table, th, tr, td, tbody, thead, text, div)
import Session exposing (Session)
import Http
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder, src)

type alias Model =
    { session: Session
    , loading: Bool
    , executors: List Executor
    , message: String
    }

type Msg
    = Reload
    | LoadResult (Result Http.Error (List Executor))
    | Error

init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , loading = True
      , executors = []
      , message = ""}
    , fetchExecutors LoadResult
    )

toSession : Model -> Session
toSession model =
    model.session

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
      Reload ->
         (model, fetchExecutors LoadResult)

      LoadResult (Ok executors) ->
         ( { model | executors = executors
                   , loading = False }, Cmd.none )

      LoadResult (Err err) ->
         ( { model | message = (Debug.toString err)
                   , executors = []
                   , loading = False }, Cmd.none )

      _ -> (model, Cmd.none)

formatTime: String -> String
formatTime time =
    time

executorRow: Executor -> Html msg
executorRow executor =
  tr []
    [ (td [] [text (String.fromInt executor.id)] )
    , (td [] [text executor.host] )
    , (td [] [text (String.fromInt executor.pid)] )
    , (td [] [text executor.executorGroup] )
    , (td [] [text (formatTime executor.started)] )
    , (td [] [text (formatTime executor.active)] )
    , (td [] [text (formatTime executor.expires)] )
    ]

executorsTable: List Executor -> List (Html msg)
executorsTable executors =
    [table [ class "pure-table" ]
      [ thead []
        [ (th [] [text "Id"])
        , (th [] [text "Host"])
        , (th [] [text "Process ID"])
        , (th [] [text "Executor group"])
        , (th [] [text "Started"])
        , (th [] [text "Activity heartbeat"])
        , (th [] [text "Heartbeat expires"])
        ]
      , tbody []
        (List.map executorRow executors)
      ]
    ]

view : Model -> { title : String, content : Html msg }
view model =
    { title = "Executors"
    , content = div [] (
      if model.loading then
        -- TODO show spinner
        -- TODO show load failed error
        [text "loading"]
      else
        executorsTable model.executors
    )
    }
