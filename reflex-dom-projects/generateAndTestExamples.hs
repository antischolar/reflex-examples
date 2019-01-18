#! /usr/bin/env nix-shell
#! nix-shell -i runghc -p "ghc.withPackages (pkgs: [ pkgs.shelly ])"

{-# LANGUAGE OverloadedStrings #-}
-- | This script provides basic tests for the try-reflex functionality; it should be run before committing code to important branches, such as 'develop'

import Shelly
import Control.Monad
import qualified Data.Text as T

examples =
  [ "BasicToDo"
  , "DragAndDrop"
  , "FileReader"
  , "NasaPod"
  , "PegSolitaire"
  , "ScreenKeyboard"
  , "TicTacToe"
  , "WebSocketEcho"
  ]

main :: IO ()
main = shelly $ verbosely $ do
  forM_ examples $ \exampleName -> do
    -- Create the cabal project skeleton
    let
      genDir = fromText "generated"
      templateDir = fromText "template"
      targetDir = genDir </> (fromText exampleName)
    rm_rf targetDir >> mkdir_p targetDir
    cp_r templateDir genDir
    mv (genDir </> templateDir </> (fromText "")) targetDir
    mv (targetDir </> (fromText "template.cabal")) (targetDir </> (fromText exampleName <.> "cabal"))
    files <- run "find" [(toTextIgnore targetDir), "-type", "f"]
    forM_ (T.words files) $ \f -> do
      let sedRegex = "s/EXAMPLENAME/" <> exampleName <> "/g"
      run_ "sed" ["-i", "-e", sedRegex, f]
    -- Copy the source code
    let
      prefixDir = (fromText "Frontend/Examples")
      srcDir = (fromText "../frontend/src/Frontend/Examples") </> (fromText exampleName)
    mkdir_p (targetDir </> prefixDir)
    cp_r srcDir (targetDir </> prefixDir)

    -- copy static assets
    let
      srcDir = (fromText "../static")
    cp_r srcDir targetDir
    -- Test cabal build
