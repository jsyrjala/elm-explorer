module Page.Data exposing (view, Msg, Model, init, update, toSession)
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


toSession : Model -> Session
toSession model =
    model.session


init : Session -> Int -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , id = id
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  (model, Cmd.none)


view : Model -> { title : String, content : Html msg }
view model =
    { title = ""
    , content = Html.text ("Data " ++ String.fromInt model.id)
    }


