--
-- | Time compatibility layer
--
module AltTime (
    ClockTime,
    getClockTime, diffClockTimes, addToClockTime, timeDiffPretty,
    module System.Time
  ) where

import Util (listToStr)

import Control.Arrow (first)

import System.Time (TimeDiff(..), noTimeDiff)
import qualified System.Time as T
  (ClockTime(..), getClockTime, diffClockTimes, addToClockTime)

-- | Wrapping ClockTime (which doesn't provide a Read instance!) seems
-- easier than talking care of the serialization of UserStatus
-- ourselves.
--
newtype ClockTime = ClockTime (T.ClockTime)

instance Show ClockTime where
  showsPrec p (ClockTime (T.TOD x y)) = showsPrec p (x,y)

instance Read ClockTime where
  readsPrec p = map (first $ ClockTime . uncurry T.TOD) . readsPrec p

-- | Retrieve the current clocktime
getClockTime :: IO ClockTime
getClockTime = ClockTime `fmap` T.getClockTime

-- | Difference of two clock times
diffClockTimes :: ClockTime -> ClockTime -> TimeDiff
diffClockTimes (ClockTime ct1) (ClockTime ct2) =
-- This is an ugly hack (we don't care about picoseconds...) to avoid the
--   "Time.toClockTime: picoseconds out of range"
-- error. I think time arithmetic is broken in GHC.
  (T.diffClockTimes ct1 ct2) { tdPicosec = 0 }

-- | @'addToClockTime' d t@ adds a time difference @d@ and a -- clock
-- time @t@ to yield a new clock time.
addToClockTime :: TimeDiff -> ClockTime -> ClockTime
addToClockTime td (ClockTime ct) = ClockTime $ T.addToClockTime td ct

-- | Pretty-print a TimeDiff. Both positive and negative Timediffs produce
--   the same output.
timeDiffPretty :: TimeDiff -> String
timeDiffPretty td = listToStr "and" $ filter (not . null) [
    prettyP years "year",
    prettyP (months `mod` 12) "month",
    prettyP (days `mod` 28) "day",
    prettyP (hours `mod` 24) "hour",
    prettyP (mins `mod` 60) "minute",
    prettyP (secs `mod` 60) "second"]
  where
    prettyP i str | i == 0    = ""
                  | i == 1    = "1 " ++ str
                  | otherwise = show i ++ " " ++ str ++ "s"

    secs = abs $ tdSec td -- This is a hack, but there wasn't an sane output
                          -- for negative TimeDiffs anyway.
    mins = secs `div` 60
    hours = mins `div` 60
    days = hours `div` 24
    months = days `div` 28
    years = months `div` 12

