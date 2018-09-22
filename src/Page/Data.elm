module Page.Data exposing (view, Msg, Model, init, update, toSession, subscriptions)
{-|
Example of query param usage
-}
import Html exposing (Html)
import Session exposing (Session)

type alias Model =
    { session: Session
    , id: Int
    }

type Msg
    = Opened
    | GotSession Session

toSession : Model -> Session
toSession model =
    model.session

subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)

init : Session -> Int -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , id = id
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
      GotSession session ->
         ( { model | session = session }, Cmd.none )

      _ -> (model, Cmd.none)


view : Model -> { title : String, content : Html msg }
view model =
    { title = ""
    , content = Html.text ("Data " ++ String.fromInt model.id)
    }


