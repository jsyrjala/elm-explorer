module Util exposing (formatTime, spinner, textElem)

import Html exposing (Html, text)


textElem : Maybe String -> Html msg
textElem value =
    case value of
        Just x ->
            text x

        Nothing ->
            text ""


formatTime : String -> String
formatTime time =
    time


spinner =
    text "loading..."
