module Route exposing (Route(..), fromUrl, href, replaceUrl, linkTo)
{-| Route implements URL based routing.

-}
import Browser.Navigation as Nav
import Html exposing (Attribute, Html, a)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, int, oneOf, s, string)


-- ROUTING


{-| Route is a location of a page

-}
type Route
    = Root
    | Data Int
    | ExecutorList
    | DefinitionList
    | Search
    | About


{-| parser parses the URL to a `Route` instance.

-}
parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map DefinitionList Parser.top
        , Parser.map Data (s "data" </> int)
        , Parser.map About (s "about")
        , Parser.map ExecutorList (s "executors")
        , Parser.map Search (s "search")
        ]



-- PUBLIC HELPERS

{-| href converts Route to textual Path.
-}
href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    -- The RealWorld spec treats the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    { url | path = Maybe.withDefault url.path url.fragment, fragment = Nothing }
        |> Parser.parse parser

linkTo: Route -> (List (Html msg)) -> Html msg
linkTo route linkContent =
  a [ href route ] linkContent

-- INTERNAL

{-| routeToString converts route to a string.
-}
routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Root ->
                    []

                DefinitionList ->
                    []

                About ->
                    [ "about" ]

                ExecutorList ->
                    [ "executors" ]

                Data id ->
                    [ "data", String.fromInt id]

                Search ->
                    [ "search" ]

    in
    "#/" ++ String.join "/" pieces
