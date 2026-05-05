module Main where

import Control.Concurrent (threadDelay)
import Control.Exception (SomeException, try)
import Config (Config, loadConfig, pollIntervalSeconds, apiKey)
import AirGradient (fetchMeasurements)
import DB (connect', initDB, insertMeasurement)
import Database.PostgreSQL.Simple (Connection)

main :: IO ()
main = do
  cfg  <- loadConfig
  conn <- connect' cfg
  initDB conn
  putStrLn "airgradient-collector started"
  loop cfg conn

loop :: Config -> Connection -> IO ()
loop cfg conn = do
  result <- try (collect cfg conn) :: IO (Either SomeException ())
  case result of
    Left  err -> putStrLn $ "error: " <> show err
    Right _   -> pure ()
  threadDelay (pollIntervalSeconds cfg * 1000000)
  loop cfg conn

collect :: Config -> Connection -> IO ()
collect cfg conn = do
  ms <- fetchMeasurements (apiKey cfg)
  mapM_ (insertMeasurement conn) ms
  putStrLn $ "stored " <> show (length ms) <> " measurement(s)"
