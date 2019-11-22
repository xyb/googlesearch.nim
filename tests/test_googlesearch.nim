# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import googlesearch

test "search nim lang":
  for result in search("nim lang", 1):
    check result.url == "https://nim-lang.org/"

test "search more pages":
  var total = 0
  for result in search("nim lang", 20):
    total += 1
  check total == 20