module Main where

import Control.Concurrent (threadDelay)
import Control.Exception (SomeException, try, fromException)
import Config (Config, loadConfig, pollIntervalSeconds, apiKey)
import AirGradient (fetchMeasurements)
import DB (connect', initDB, insertMeasurement)
import Database.PostgreSQL.Simple (Connection, SqlError, close)

main :: IO ()
main = do
  cfg  <- loadConfig
  conn <- connect' cfg
  initDB conn
  putStrLn "airgradient-collector started"
  loop cfg conn

loop :: Config -> Connection -> IO ()
loop cfg conn = do
  conn' <- runCollect cfg conn
  threadDelay (pollIntervalSeconds cfg * 1000000)
  loop cfg conn'

runCollect :: Config -> Connection -> IO Connection
runCollect cfg conn = do
  result <- try (collect cfg conn) :: IO (Either SomeException ())
  case result of
    Right _  -> pure conn
    Left err -> do
      putStrLn $ "error: " <> show err
      case fromException err :: Maybe SqlError of
        Just _  -> reconnect cfg conn
        Nothing -> pure conn

reconnect :: Config -> Connection -> IO Connection
reconnect cfg oldConn = do
  _ <- try (close oldConn) :: IO (Either SomeException ())
  result <- try (connect' cfg) :: IO (Either SomeException Connection)
  case result of
    Left err   -> do
      putStrLn $ "reconnect failed: " <> show err
      pure oldConn
    Right conn -> do
      putStrLn "reconnected to database"
      pure conn

collect :: Config -> Connection -> IO ()
collect cfg conn = do
  ms <- fetchMeasurements (apiKey cfg)
  mapM_ (insertMeasurement conn) ms
  putStrLn $ "stored " <> show (length ms) <> " measurement(s)"