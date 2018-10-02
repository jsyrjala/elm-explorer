module Route exposing
    ( Route(..)
    , SearchQueryParams
    , fromUrl
    , href
    , linkTo
    , replaceUrl
    )

{-| Route implements URL based routing.
-}

import Array
import Browser.Navigation as Nav
import Dict
import Html exposing (Attribute, Html, a)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, int, oneOf, s, string)
import Url.Parser.Query



-- ROUTING


{-| Route is a location of a page
-}
type Route
    = Root
    | InstanceDetails Int
    | DefinitionDetails String
    | ExecutorList
    | DefinitionList
    | Search SearchQueryParams
    | About


type alias SearchQueryParams =
    { workflowType : Maybe String
    , businessKey : Maybe String
    , externalId : Maybe String
    , workflowId : Maybe String
    , parentWorkflowId : Maybe String
    }


searchParams : Url.Parser.Query.Parser SearchQueryParams
searchParams =
    Url.Parser.Query.map5 SearchQueryParams
        (Url.Parser.Query.string "type")
        (Url.Parser.Query.string "businessKey")
        (Url.Parser.Query.string "externalId")
        (Url.Parser.Query.string "workflowId")
        (Url.Parser.Query.string "parentWorkflowId")


{-| parser parses the URL to a `Route` instance.
-}
parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map DefinitionList Parser.top
        , Parser.map Search (s "search" <?> searchParams)
        , Parser.map InstanceDetails (s "workflow" </> int)
        , Parser.map DefinitionDetails (s "workflow-definition" </> string)
        , Parser.map ExecutorList (s "executors")
        , Parser.map About (s "about")
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
    let
        path =
            case url.fragment of
                Just fragment ->
                    Maybe.withDefault "" (List.head (String.split "?" fragment))

                Nothing ->
                    url.path

        query =
            case url.fragment of
                Just fragment ->
                    Array.get 1 (Array.fromList (String.split "?" fragment))

                Nothing ->
                    url.query
    in
    -- Convert # fragment to path and query
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    { url | path = path, query = query, fragment = Nothing }
        |> Parser.parse parser


linkTo : Route -> List (Html msg) -> Html msg
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

                InstanceDetails id ->
                    [ "workflow", String.fromInt id ]

                DefinitionDetails workflowType ->
                    [ "workflow-definition", workflowType ]

                Search _ ->
                    [ "search" ]
    in
    "#/" ++ String.join "/" pieces
