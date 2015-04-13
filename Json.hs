{-# LANGUAGE OverloadedStrings #-}

module Json(File(..),
            Datas(..),
            listFiles_to_data
          )
where

import Control.Applicative ((<$>), (<*>))
import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as BL
import Control.Monad (mzero)

data File = File {
  path :: String,
--  nameFile :: String,
  sizeFile :: Integer
  }
  deriving (Show)

data Datas = Datas {
  idClient :: Double,
  allFiles :: [File]
  }
  deriving (Show)

instance FromJSON Datas where
  parseJSON (Object o) =
    Datas <$> (o .: "idClient")
    <*> (o .: "allFiles")
  parseJSON _ = mzero

instance FromJSON File where
  parseJSON (Object o) =
    File <$> (o .: "path")
--    <*> (o .: "nameFile")
    <*> (o .: "sizeFile")
  parseJSON _ = mzero

instance ToJSON Datas where
  toJSON (Datas idC allFiles) = object ["idClient" .= idC, "allFiles" .= allFiles]

instance ToJSON File where
  toJSON (File path sizeFile) = object ["path" .= path, "sizeFile" .= sizeFile]


listFiles_to_data :: [(String, Integer)] -> [File]
listFiles_to_data [] = []
listFiles_to_data ((p,sf):ls) = 
              let h = File{path=p ,sizeFile=sf} in 
              (h:listFiles_to_data ls)

