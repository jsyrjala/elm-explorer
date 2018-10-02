module RouteTests exposing (allSearchParams, fromUrlTest, noSearchParams, query, searchFragmentUrl, searchFullParamsFragmentUrl, searchFullParamsUrl, searchUrl)

import Expect
import Route exposing (Route(..), SearchQueryParams, fromUrl)
import Test exposing (..)
import Url exposing (Url)


searchUrl =
    Url Url.Http "www.nflow.io" Nothing "search" Nothing Nothing


searchFragmentUrl =
    Url Url.Http "www.nflow.io" Nothing "" Nothing (Just "search")


query =
    "type=workT&businessKey=b-key&workflowId=99&parentWorkflowId=42&externalId=ext-key&unknownParam=value"


searchFullParamsUrl =
    Url Url.Http "www.nflow.io" Nothing "search" (Just query) Nothing


searchFullParamsFragmentUrl =
    Url Url.Http "www.nflow.io" Nothing "" Nothing (Just ("search?" ++ query))


noSearchParams =
    SearchQueryParams Nothing Nothing Nothing Nothing Nothing


allSearchParams =
    SearchQueryParams (Just "workT") (Just "b-key") (Just "ext-key") (Just "99") (Just "42")


fromUrlTest : Test
fromUrlTest =
    describe "RouteParser"
        [ test "fromUrl search" <|
            \_ ->
                let
                    route =
                        fromUrl searchUrl

                    expectedRoute =
                        Just (Search noSearchParams)
                in
                Expect.equal expectedRoute route
        , test "fromUrl search fragment" <|
            \_ ->
                let
                    route =
                        fromUrl searchFragmentUrl

                    expectedRoute =
                        Just (Search noSearchParams)
                in
                Expect.equal expectedRoute route
        , test "fromUrl search with all parameters" <|
            \_ ->
                let
                    route =
                        fromUrl searchFullParamsUrl

                    expectedRoute =
                        Just (Search allSearchParams)
                in
                Expect.equal expectedRoute route
        , test "fromUrl search fragment with all parameters" <|
            \_ ->
                let
                    route =
                        fromUrl searchFullParamsFragmentUrl

                    expectedRoute =
                        Just (Search allSearchParams)
                in
                Expect.equal expectedRoute route
        ]
