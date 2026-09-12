-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE Rank2Types #-}

{- |

Module    :  Test.BDD.Language
Copyright :  (c) Paolo Veronelli, Pavlo Kerestey 2017
License   :  BSD3
Maintainer:  paolo.veronelli@gmail.com
Stability :  experimental
Portability: non-portable


The constrained language to define behaviors in BDD terminology

@
exampleL :: TestTree
exampleL = testBehavior "Test sequence"
    $ Given (print "Some effect")
    $ Given (print "Another effect")
    $ GivenAndAfter (print "Aquiring resource" >> return "Resource 1")
                   (print . ("Release "++))
    $ GivenAndAfter (print "Aquiring resource" >> return "Resource 2")
                   (print . ("Release "++))
    $ When (print "Action returning" >> return ([1..10]++[100..106]) :: IO [Int])
    $ Then (@?= ([1..10]++[700..706]))
    $ End
@
-}
module Test.BDD.Language
    ( Language (..)
    , BDDPreparing
    , BDDTesting
    , BDDTest (..)
    , TestContext (..)
    , context
    , when
    , tests
    , interpret
    , Phase (..)
    )
where

import Lens.Micro

-- | Separating the 2 phases by type
data Phase = Preparing | Testing

-- | Recording given actions and type related teardowns
data TestContext m = forall r. TestContext (m r) (r -> m ())

-- | Bare hoare language
data Language m t q a where
    -- | action to prepare the test
    Given
        :: m ()
        -> Language m t q 'Preparing
        -> Language m t q 'Preparing
    -- | action to prepare the test, and related teardown action
    GivenAndAfter
        :: m r
        -> (r -> m ())
        -> Language m t q 'Preparing
        -> Language m t q 'Preparing
    -- | core logic of the test (last preparing action)
    When
        :: m t
        -> Language m t q 'Testing
        -> Language m t q 'Preparing
    -- | action producing a test
    Then
        :: (t -> m q)
        -> Language m t q 'Testing
        -> Language m t q 'Testing
    -- | final placeholder
    End :: Language m t q 'Testing

-- | Result of this module interpreter
data BDDTest m t q = BDDTest
    { _tests :: [t -> m q]
    -- ^ tests from @t@
    , _context :: [TestContext m]
    -- ^ test context
    , _when :: m t
    -- ^ when action to compute @t@
    }

-- | Lens for the ordered preparation actions and their teardowns.
context
    :: (Functor f)
    => ([TestContext m] -> f [TestContext m])
    -> BDDTest m t q
    -> f (BDDTest m t q)
context f (BDDTest ts c w) = (\c' -> BDDTest ts c' w) <$> f c

-- | Lens for the assertions, allowing their result type to change.
tests
    :: (Functor f)
    => ([t -> m q1] -> f [t -> m q2])
    -> BDDTest m t q1
    -> f (BDDTest m t q2)
tests f (BDDTest ts c w) = (\ts' -> BDDTest ts' c w) <$> f ts

-- | Lens for the action whose result is supplied to the assertions.
when
    :: (Functor f)
    => (m t -> f (m t))
    -> BDDTest m t q
    -> f (BDDTest m t q)
when f (BDDTest ts c w) = BDDTest ts c <$> f w

-- | Preparing language types
type BDDPreparing m t q = Language m t q 'Preparing

-- | Testing language types
type BDDTesting m t q = Language m t q 'Testing

-- | An interpreter collecting the actions
interpret :: (Monad m) => Language m t q a -> BDDTest m t q
interpret (Given given p) =
    interpret $ GivenAndAfter given (const $ return ()) p
interpret (GivenAndAfter given after p) =
    over context ((:) $ TestContext given after) $
        interpret p
interpret (When fa p) =
    set when fa $ interpret p
interpret (Then ca p) = over tests (ca :) $ interpret p
interpret End =
    BDDTest [] [] $
        error "End on its own does not make sense as a test"
