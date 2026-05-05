{-# LANGUAGE OverloadedStrings #-}
module AirGradient (Measurement (..), fetchMeasurements) where

import Data.Aeson
import Data.Text (Text)
import Data.Time (UTCTime)
import Network.HTTP.Client
import Network.HTTP.Client.TLS (newTlsManager)

data Measurement = Measurement
  { locationId :: Int
  , serialNo   :: Maybe Text
  , timestamp  :: UTCTime
  , pm01       :: Maybe Double
  , pm02       :: Maybe Double
  , pm10       :: Maybe Double
  , rco2       :: Maybe Int
  , tvoc       :: Maybe Double
  , tvocIndex  :: Maybe Int
  , noxIndex   :: Maybe Int
  , atmp       :: Maybe Double
  , rhum       :: Maybe Double
  , wifi       :: Maybe Int
  } deriving (Show)

instance FromJSON Measurement where
  parseJSON = withObject "Measurement" $ \o ->
    Measurement
      <$> o .:  "locationId"
      <*> o .:? "serialno"
      <*> o .:  "timestamp"
      <*> o .:? "pm01"
      <*> o .:? "pm02"
      <*> o .:? "pm10"
      <*> o .:? "rco2"
      <*> o .:? "tvoc"
      <*> o .:? "tvocIndex"
      <*> o .:? "noxIndex"
      <*> o .:? "atmp"
      <*> o .:? "rhum"
      <*> o .:? "wifi"

fetchMeasurements :: String -> IO [Measurement]
fetchMeasurements apiKey = do
  manager <- newTlsManager
  let url = "https://api.airgradient.com/public/api/v1/locations/measures/current?token=" <> apiKey
  request <- parseRequest url
  response <- httpLbs request manager
  case eitherDecode (responseBody response) of
    Left err -> do
      putStrLn $ "JSON parse error: " <> err
      pure []
    Right ms -> pure ms