module Api.NflowApi exposing (Executor, executorDecoder, executorEncoder)

import Json.Decode as D
import Json.Encode as E

-- [{"id":1,"host":"nbank-demo-1","pid":1197,"executorGroup":"nflow","started":"2018-08-16T18:14:38.170Z","active":"2018-09-16T18:52:44.857Z","expires":"2018-09-16T19:07:44.857Z"}]

type alias Executor =
     { id: Int
     , host: String
     , pid: Int
     , executorGroup: String
     , started: String -- TODO timestamp parsing?
     , active: String
     , expires: String
     }

executorEncoder : Executor -> E.Value
executorEncoder executor =
  E.object
    [ ("id", E.int executor.id)
    , ("host", E.string executor.host)
    , ("pid", E.int executor.pid)
    , ("executorGroup", E.string executor.executorGroup)
    , ("started", E.string executor.started)
    , ("active", E.string executor.active)
    , ("expires", E.string executor.expires)
    ]

-- TODO use pipeline decoder
-- https://gist.github.com/nojaf/3d529a68e9a75850a42a8e1ebc040899
executorDecoder : D.Decoder Executor
executorDecoder =
    D.map7 Executor
      (D.field "id" D.int)
      (D.field "host" D.string)
      (D.field "pid" D.int)
      (D.field "executorGroup" D.string)
      (D.field "started" D.string)
      (D.field "active" D.string)
      (D.field "expires" D.string)

