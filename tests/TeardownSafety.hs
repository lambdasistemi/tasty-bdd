{-# LANGUAGE LambdaCase #-}

{- |
Module    : TeardownSafety
Copyright :  (c) Paolo Veronelli 2026
License   :  BSD-3-Clause

Every resource acquired by a scenario is released however the scenario
fails. Each scenario runs through tasty's own 'launchTestTree'; the tests
assert the exact list of released resources, in release order, and the
result tasty reports.
-}
module TeardownSafety (teardownSafetyTests) where

import Control.Concurrent.STM (atomically, readTVar, retry)
import Control.Exception (throwIO)
import Data.Foldable (toList)
import Data.IORef (modifyIORef, newIORef, readIORef)
import Data.List (isInfixOf)
import Test.BDD.LanguageFree (givenAndAfter_, then_, when_)
import qualified Test.HUnit as H
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.Bdd
    ( Language (..)
    , testBehavior
    , testBehaviorF
    , (@?=)
    )
import Test.Tasty.HUnit (assertFailure, testCase)
import Test.Tasty.Ingredients.FailFast (FailFast (..))
import Test.Tasty.Options (OptionSet, setOption)
import Test.Tasty.Runners
    ( Outcome (..)
    , Result (..)
    , Status (..)
    , launchTestTree
    )

-- | Records the name of a resource when its teardown runs.
type Release = String -> IO ()

-- | A teardown that records the resource, then throws.
throwingRelease :: Release -> String -> IO ()
throwingRelease release r = do
    release r
    throwIO $ userError $ "teardown " ++ r

{- | Run a single-test tree with tasty and return the released resources,
in release order, with the result tasty reports for the test.
-}
observe :: OptionSet -> (Release -> TestTree) -> IO ([String], Result)
observe opts scenario = do
    ref <- newIORef []
    results <-
        launchTestTree opts (scenario $ \r -> modifyIORef ref (r :)) $
            \smap -> do
                done <- atomically $ traverse waitDone smap
                pure $ \_ -> pure $ toList done
    released <- reverse <$> readIORef ref
    case results of
        [result] -> pure (released, result)
        _ -> assertFailure $ "expected one test, got " ++ show (length results)
  where
    waitDone tv =
        readTVar tv >>= \case
            Done result -> pure result
            _ -> retry

failFastOff :: OptionSet
failFastOff = mempty

failFastOn :: OptionSet
failFastOn = setOption (FailFast True) mempty

assertPassed :: Result -> IO ()
assertPassed result = case resultOutcome result of
    Success -> pure ()
    Failure _ ->
        assertFailure $ "expected a pass, got: " ++ resultDescription result

-- | The test failed and its reported reason mentions the given text.
assertFailedWith :: String -> Result -> IO ()
assertFailedWith reason result = case resultOutcome result of
    Success -> assertFailure $ "expected a failure mentioning " ++ show reason
    Failure _ ->
        H.assertBool
            ( "reported reason "
                ++ show (resultDescription result)
                ++ " does not mention "
                ++ show reason
            )
            $ reason `isInfixOf` resultDescription result

-- | The reported reason does not mention the given text.
assertNotMentioning :: String -> Result -> IO ()
assertNotMentioning text result =
    H.assertBool
        ( "reported reason "
            ++ show (resultDescription result)
            ++ " mentions "
            ++ show text
        )
        $ not
        $ text `isInfixOf` resultDescription result

boom :: IO a
boom = throwIO $ userError "boom in step"

teardownSafetyTests :: TestTree
teardownSafetyTests =
    testGroup
        "teardown safety"
        [ testGroup "constructor runner" constructorTests
        , testGroup "free runner" freeTests
        ]

constructorTests :: [TestTree]
constructorTests =
    [ testCase
        "pass: every resource released in reverse order, reported passed"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "pass" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (pure (1 :: Int)) $
                                Then (@?= 1) End
            released H.@?= ["r2", "r1"]
            assertPassed result
    , testCase
        "equality-failure: every resource released in reverse order, reported failed"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "equality-failure" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (pure (1 :: Int)) $
                                Then (@?= 2) End
            released H.@?= ["r2", "r1"]
            assertFailedWith "Expected equality" result
    , testCase
        "when-throws: every resource released in reverse order, reported failed"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "when-throws" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (boom :: IO Int) $
                                Then (@?= 1) End
            released H.@?= ["r2", "r1"]
            assertFailedWith "boom in step" result
    , testCase
        "then-throws: every resource released in reverse order, reported failed"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "then-throws" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (pure (1 :: Int)) $
                                Then (\_ -> assertFailure "assertion in then") End
            released H.@?= ["r2", "r1"]
            assertFailedWith "assertion in then" result
    , testCase
        "acquisition-throws: resources acquired before it released in reverse order, reported failed"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "acquisition-throws"
                    $ GivenAndAfter (pure "r1") release
                    $ GivenAndAfter (pure "r2") release
                    $ GivenAndAfter
                        (throwIO (userError "acquisition of r3") :: IO String)
                        release
                    $ GivenAndAfter (pure "r4") release
                    $ When (pure (1 :: Int))
                    $ Then (@?= 1) End
            released H.@?= ["r2", "r1"]
            assertFailedWith "acquisition of r3" result
    , testCase "teardown-throws: the remaining teardowns still run" $ do
        (released, _) <- observe failFastOff $ \release ->
            testBehavior "teardown-throws" $
                GivenAndAfter (pure "r1") release $
                    GivenAndAfter (pure "r2") (throwingRelease release) $
                        GivenAndAfter (pure "r3") release $
                            When (pure (1 :: Int)) $
                                Then (@?= 1) End
        released H.@?= ["r3", "r2", "r1"]
    , testCase
        "teardown-throws after passing steps: reported failed by the teardown"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "teardown-throws after passing steps" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") (throwingRelease release) $
                            When (pure (1 :: Int)) $
                                Then (@?= 1) End
            released H.@?= ["r2", "r1"]
            assertFailedWith "teardown r2" result
    , testCase
        "when-throws with a throwing teardown: the step's failure is reported"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "when-throws with a throwing teardown" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") (throwingRelease release) $
                            When (boom :: IO Int) $
                                Then (@?= 1) End
            assertFailedWith "boom in step" result
            assertNotMentioning "teardown r2" result
            released H.@?= ["r2", "r1"]
    , testCase
        "equality-failure with a throwing teardown: the step's failure is reported"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehavior "equality-failure with a throwing teardown" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") (throwingRelease release) $
                            When (pure (1 :: Int)) $
                                Then (@?= 2) End
            assertFailedWith "Expected equality" result
            assertNotMentioning "teardown r2" result
            released H.@?= ["r2", "r1"]
    , testCase
        "fail-fast on, equality-failure: teardown skipped, reported failed"
        $ do
            (released, result) <- observe failFastOn $ \release ->
                testBehavior "fail-fast equality-failure" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (pure (1 :: Int)) $
                                Then (@?= 2) End
            released H.@?= []
            assertFailedWith "Expected equality" result
    , testCase
        "fail-fast on, when-throws: teardown skipped, reported failed"
        $ do
            (released, result) <- observe failFastOn $ \release ->
                testBehavior "fail-fast when-throws" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (boom :: IO Int) $
                                Then (@?= 1) End
            released H.@?= []
            assertFailedWith "boom in step" result
    , testCase
        "fail-fast on, pass: every resource released in reverse order, reported passed"
        $ do
            (released, result) <- observe failFastOn $ \release ->
                testBehavior "fail-fast pass" $
                    GivenAndAfter (pure "r1") release $
                        GivenAndAfter (pure "r2") release $
                            When (pure (1 :: Int)) $
                                Then (@?= 1) End
            released H.@?= ["r2", "r1"]
            assertPassed result
    ]

freeTests :: [TestTree]
freeTests =
    [ testCase
        "free-when-throws: every resource released in reverse order, reported failed"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehaviorF id "free-when-throws" $ do
                    givenAndAfter_ (pure "r1") release
                    givenAndAfter_ (pure "r2") release
                    when_ (boom :: IO Int) $ then_ (@?= 1)
            released H.@?= ["r2", "r1"]
            assertFailedWith "boom in step" result
    , testCase "free-teardown-throws: the remaining teardowns still run" $ do
        (released, _) <- observe failFastOff $ \release ->
            testBehaviorF id "free-teardown-throws" $ do
                givenAndAfter_ (pure "r1") release
                givenAndAfter_ (pure "r2") $ throwingRelease release
                givenAndAfter_ (pure "r3") release
                when_ (pure (1 :: Int)) $ then_ (@?= 1)
        released H.@?= ["r3", "r2", "r1"]
    , testCase
        "free-teardown-throws after passing steps: reported failed by the teardown"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehaviorF id "free-teardown-throws after passing steps" $ do
                    givenAndAfter_ (pure "r1") release
                    givenAndAfter_ (pure "r2") $ throwingRelease release
                    when_ (pure (1 :: Int)) $ then_ (@?= 1)
            released H.@?= ["r2", "r1"]
            assertFailedWith "teardown r2" result
    , testCase
        "free-when-throws with a throwing teardown: the step's failure is reported"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehaviorF id "free-when-throws with a throwing teardown" $ do
                    givenAndAfter_ (pure "r1") release
                    givenAndAfter_ (pure "r2") $ throwingRelease release
                    when_ (boom :: IO Int) $ then_ (@?= 1)
            assertFailedWith "boom in step" result
            assertNotMentioning "teardown r2" result
            released H.@?= ["r2", "r1"]
    , testCase
        "free equality-failure with a throwing teardown: the step's failure is reported"
        $ do
            (released, result) <- observe failFastOff $ \release ->
                testBehaviorF id "free equality-failure with a throwing teardown" $ do
                    givenAndAfter_ (pure "r1") release
                    givenAndAfter_ (pure "r2") $ throwingRelease release
                    when_ (pure (1 :: Int)) $ then_ (@?= 2)
            assertFailedWith "Expected equality" result
            assertNotMentioning "teardown r2" result
            released H.@?= ["r2", "r1"]
    ]
