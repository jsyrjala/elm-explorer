module Page.Blank exposing (Model, Msg, view)

import Html exposing (Html)
import Session exposing (Session)


type alias Model =
    { data : String
    }


type Msg
    = Opened


view : { title : String, content : Html msg }
view =
    { title = ""
    , content = Html.text "Blank"
    }
