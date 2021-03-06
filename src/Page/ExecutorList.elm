module Page.ExecutorList exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| Executors list
-}

import Api.NflowApi exposing (Executor, fetchExecutors)
import Html exposing (Html, div, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder, src)
import Http
import Session exposing (Session)
import Time exposing (Posix)


type alias Model =
    { session : Session
    , loading : Bool
    , executors : List Executor
    , message : String
    }


type Msg
    = Reload
    | LoadResult (Result Http.Error (List Executor))
    | Error
    | GotSession Session


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , loading = True
      , executors = []
      , message = ""
      }
    , fetchExecutors session.config LoadResult
    )


toSession : Model -> Session
toSession model =
    model.session


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Session.changes GotSession (Session.navKey model.session)
        , Time.every (60 * 1000.0) (\_ -> Reload)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSession session ->
            ( { model | session = session }, Cmd.none )

        Reload ->
            ( model, fetchExecutors model.session.config LoadResult )

        LoadResult (Ok executors) ->
            ( { model
                | executors = executors
                , loading = False
              }
            , Cmd.none
            )

        LoadResult (Err err) ->
            ( { model
                | message = Debug.toString err
                , executors = []
                , loading = False
              }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )



-- TODO move to util


formatTime : String -> String
formatTime time =
    time


executorRow : Executor -> Html msg
executorRow executor =
    tr []
        [ td [] [ text (String.fromInt executor.id) ]
        , td [] [ text executor.host ]
        , td [] [ text (String.fromInt executor.pid) ]
        , td [] [ text executor.executorGroup ]
        , td [] [ text (formatTime executor.started) ]
        , td [] [ text (formatTime executor.active) ]
        , td [] [ text (formatTime executor.expires) ]
        ]


executorsTable : List Executor -> List (Html msg)
executorsTable executors =
    [ table [ class "pure-table" ]
        [ thead []
            [ th [] [ text "Id" ]
            , th [] [ text "Host" ]
            , th [] [ text "Process ID" ]
            , th [] [ text "Executor group" ]
            , th [] [ text "Started" ]
            , th [] [ text "Activity heartbeat" ]
            , th [] [ text "Heartbeat expires" ]
            ]
        , tbody []
            (List.map executorRow executors)
        ]
    ]


view : Model -> { title : String, content : Html msg }
view model =
    { title = "Executors"
    , content =
        div []
            (if model.loading then
                -- TODO show spinner
                -- TODO show load failed error
                [ text "loading" ]

             else
                executorsTable model.executors
            )
    }
