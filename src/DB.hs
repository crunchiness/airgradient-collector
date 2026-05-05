{-# LANGUAGE OverloadedStrings #-}
module DB (connect', initDB, insertMeasurement) where

import Control.Monad (void)
import Config (Config (..))
import AirGradient (Measurement (..))
import Database.PostgreSQL.Simple

connect' :: Config -> IO Connection
connect' cfg = connect defaultConnectInfo
  { connectHost     = dbHost cfg
  , connectPort     = dbPort cfg
  , connectDatabase = dbName cfg
  , connectUser     = dbUser cfg
  , connectPassword = dbPassword cfg
  }

initDB :: Connection -> IO ()
initDB conn = do
  void $ execute_ conn
    "CREATE TABLE IF NOT EXISTS measurements \
    \( id          SERIAL PRIMARY KEY \
    \, location_id INTEGER       NOT NULL \
    \, serial_no   TEXT \
    \, timestamp   TIMESTAMPTZ   NOT NULL \
    \, pm01        DOUBLE PRECISION \
    \, pm02        DOUBLE PRECISION \
    \, pm10        DOUBLE PRECISION \
    \, rco2        INTEGER \
    \, tvoc        DOUBLE PRECISION \
    \, tvoc_index  INTEGER \
    \, nox_index   INTEGER \
    \, atmp        DOUBLE PRECISION \
    \, rhum        DOUBLE PRECISION \
    \, wifi        INTEGER \
    \, created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW() \
    \)"
  void $ execute_ conn
    "CREATE UNIQUE INDEX IF NOT EXISTS measurements_location_timestamp \
    \ON measurements (location_id, timestamp)"

insertMeasurement :: Connection -> Measurement -> IO ()
insertMeasurement conn m = void $ execute conn
  "INSERT INTO measurements \
  \(location_id, serial_no, timestamp, pm01, pm02, pm10, rco2, tvoc, tvoc_index, nox_index, atmp, rhum, wifi) \
  \VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) \
  \ON CONFLICT (location_id, timestamp) DO NOTHING"
  ( locationId m, serialNo m, timestamp m
  , pm01 m, pm02 m, pm10 m
  , rco2 m, tvoc m, tvocIndex m, noxIndex m
  , atmp m, rhum m, wifi m
  )