{-# OPTIONS -Wall #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Main entry point.

module Main (main) where

import Hpaste.Config
import Hpaste.Controller.Activity as Activity
import Hpaste.Controller.Browse   as Browse
import Hpaste.Controller.Diff     as Diff
import Hpaste.Controller.Home     as Home
import Hpaste.Controller.New      as New
import Hpaste.Controller.Paste    as Paste
import Hpaste.Controller.Raw      as Raw
import Hpaste.Controller.Report   as Report
import Hpaste.Controller.Reported as Reported
import Hpaste.Controller.Rss      as Rss
import Hpaste.Controller.Script   as Script
import Hpaste.Model.Announcer     (newAnnouncer)
import Hpaste.Types
import Hpaste.Types.Announcer

import Control.Concurrent.Chan    (Chan)
import Data.Text.Lazy             (Text)
import System.Environment
import Snap.App
import Snap.Http.Server           hiding (Config)
import Snap.Util.FileServe


-- | Main entry point.
main :: IO ()
main = do
  cpath:_ <- getArgs
  config <- getConfig cpath
  announces <- newAnnouncer (configAnnounce config)
  pool <- newPool (configPostgres config)
  setUnicodeLocale "en_US"
  httpServe server (serve config pool announces)
 where server = setPort 10000 defaultConfig

-- | Serve the controllers.
serve :: Config -> Pool -> Announcer -> Snap ()
serve config pool ans = route routes where
  routes = [("/css/",serveDirectory "static/css")
           ,("/js/amelie.hs.js",run Script.handle)
           ,("/js/",serveDirectory "static/js")
           ,("/hs/",serveDirectory "static/hs")
           ,("",run (Home.handle False))
	   ,("/spam",run (Home.handle True))
           ,("/:id",run (Paste.handle False))
           ,("/raw/:id",run Raw.handle)
           ,("/revision/:id",run (Paste.handle True))
           ,("/report/:id",run Report.handle)
           ,("/reported",run Reported.handle)
           ,("/new",run (New.handle New.NewPaste))
           ,("/annotate/:id",run (New.handle New.AnnotatePaste))
           ,("/edit/:id",run (New.handle New.EditPaste))
           ,("/new/:channel",run (New.handle New.NewPaste))
           ,("/browse",run Browse.handle)
           ,("/activity",run Activity.handle)
           ,("/diff/:this/:that",run Diff.handle)
	   ,("/delete",run Report.handleDelete)
           ,("/channel/:channel/rss",run Rss.handle)
           ]
  run = runHandler ans config pool
