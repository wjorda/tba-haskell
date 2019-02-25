{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module TBA where
 
import TBA.Match

import Network.Wreq

import Control.Lens
import Data.Aeson
import Data.Aeson.Types
import Data.Aeson.Lens (_String, _Double, _Integer, AsValue, key, values, nth)
import Data.Scientific

import qualified Network.Wreq.Session as S
import qualified Data.Text as T
import qualified Data.Set as DS

data TBAClient = TBAClient {
    tbaAuth :: T.Text
    , tbaSession :: S.Session
}

tbaNew :: T.Text -> IO TBAClient
tbaNew tbaAuth = do
    tbaSession <- S.newSession
    return TBAClient{..}

tbaParams client = defaults & param "X-TBA-Auth-Key" .~ [tbaAuth client]

tbaRequest :: (FromJSON a) => String -> TBAClient -> IO (Response a)
tbaRequest path client = do
    let params = tbaParams client
    let sess = tbaSession client
    let url = "https://www.thebluealliance.com/api/v3/" ++ path
    
    -- echo url to console for debugging
    putStrLn url

    -- make request and parse as json
    resp <- S.getWith params sess url
    asJSON resp

tbaEventMatches :: String -> TBAClient -> IO (Response [Match])
tbaEventMatches eventCode = tbaRequest ("event/" ++ eventCode ++ "/matches")

tbaSingleMatch :: String -> TBAClient -> IO (Response Match)
tbaSingleMatch matchKey = tbaRequest ("match/" ++ matchKey)

teamNumSet :: String -> TBAClient -> IO (DS.Set Integer)
teamNumSet dName client = do
    let path = "district/" ++ dName ++ "/teams"
    dTeamsJson <- tbaRequest path client :: IO (Response Array)
    let dSet = DS.fromList $ dTeamsJson ^.. responseBody . traverse . key "team_number" . _Integer
    return dSet