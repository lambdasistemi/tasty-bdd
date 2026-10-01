{- | Capture process-wide standard output while suppressing action exceptions.

Module: System.CaptureStdout
License: BSD-3-Clause
Credits: Merijn Verstraaten
-}
module System.CaptureStdout (captureStdout) where

import Control.Exception (SomeException, bracket, try)
import Data.Text
import Data.Text.IO (hGetContents)
import GHC.IO.Handle (hDuplicate, hDuplicateTo)
import System.IO (Handle, SeekMode (..), hFlush, hSeek, stdout)
import System.IO.Temp (withSystemTempFile)

-- | Capture output using a temporary file. Concurrent captures are not isolated.
captureStdout :: String -> IO () -> IO Text
captureStdout tmp act = withSystemTempFile tmp $ \_ hnd -> do
    let redirect :: IO Handle
        redirect = do
            hFlush stdout
            hDuplicate stdout <* hDuplicateTo hnd stdout

        undo :: Handle -> IO ()
        undo h = hFlush stdout >> hDuplicateTo h stdout

    _ <- bracket redirect undo $ \_ -> try act :: IO (Either SomeException ())

    hSeek hnd AbsoluteSeek 0
    hGetContents hnd
