import unittest

import googlesearch

test "search nim lang":
  for result in search("Nim programming language", 1):
    check result.url == "https://nim-lang.org/"

test "search more pages":
  var total = 0
  for result in search("nim lang", 20):
    total += 1
  check total == 20
