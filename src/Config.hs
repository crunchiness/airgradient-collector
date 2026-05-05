module Config where

import Data.Maybe (fromMaybe)
import Data.Word (Word16)
import System.Environment (getEnv, lookupEnv)
import Text.Read (readMaybe)

data Config = Config
  { apiKey              :: String
  , dbHost              :: String
  , dbPort              :: Word16
  , dbName              :: String
  , dbUser              :: String
  , dbPassword          :: String
  , pollIntervalSeconds :: Int
  }

loadConfig :: IO Config
loadConfig = do
  key      <- getEnv "API_KEY"
  host     <- env "DB_HOST"     "postgres"
  portStr  <- env "DB_PORT"     "5432"
  name     <- env "DB_NAME"     "airgradient"
  user     <- env "DB_USER"     "postgres"
  password <- env "DB_PASSWORD" ""
  pure Config
    { apiKey              = key
    , dbHost              = host
    , dbPort              = fromMaybe 5432 (readMaybe portStr)
    , dbName              = name
    , dbUser              = user
    , dbPassword          = password
    , pollIntervalSeconds = 60
    }
  where
    env k def = fromMaybe def <$> lookupEnv k
