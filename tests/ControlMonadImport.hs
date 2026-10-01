{- |
Module    : ControlMonadImport
Copyright :  (c) Paolo Veronelli 2026
License   :  BSD-3-Clause

A scenario module imports "Test.BDD.Language" and "Control.Monad" together,
unqualified, and uses 'when' as the monadic conditional. The module itself
is the proof: it compiles only while the language exports no name that
clashes with "Control.Monad".
-}
module ControlMonadImport (controlMonadImportTests) where

import Control.Monad
import Data.Functor.Const (Const (..))
import Data.Functor.Identity (Identity (..))
import Data.IORef (modifyIORef, newIORef, readIORef)
import Test.BDD.Language
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

-- | 'when' and 'whenAction' used side by side in one scenario module.
controlMonadImportTests :: TestTree
controlMonadImportTests =
    testGroup
        "Test.BDD.Language imported next to Control.Monad"
        [ testCase "when is the monadic conditional inside a scenario action" $ do
            seen <- newIORef []
            let
                action = do
                    forM_ [1 .. 4 :: Int] $ \i ->
                        when (even i) $ modifyIORef seen (i :)
                    pure "done"
            result <- _when $ scenario action
            result @?= "done"
            readIORef seen >>= (@?= [4, 2])
        , testCase "whenAction reads and replaces the action of a scenario" $ do
            getConst (whenAction Const $ scenario $ pure "first")
                >>= (@?= "first")
            let
                replaced =
                    runIdentity $
                        whenAction
                            (const $ Identity $ pure "second")
                            (scenario $ pure "first")
            _when replaced >>= (@?= "second")
        ]
  where
    scenario :: IO String -> BDDTest IO String ()
    scenario action = interpret $ When action $ Then (\_ -> pure ()) End
