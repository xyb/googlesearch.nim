## Nim library for scraping google search results.

import httpclient
import math
import os
import re
import sequtils
import strformat
import strutils
import uri
import xmltree
from htmlparser import parseHtml
from streams import newStringStream

import nimquery

type
  SearchResult* = object
    url*: string
    title*: string
    snippet*: string

const
  USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/76.0.3809.100 Safari/537.36"
  SEARCH_URL = "https://google.com/search"

proc newProxyHttpClient(): HttpClient =
  var proxyUrl = ""
  try:
    if existsEnv("http_proxy"):
      proxyUrl = getEnv("http_proxy")
    elif existsEnv("https_proxy"):
      proxyUrl = getEnv("https_proxy")
  except ValueError:
    discard

  if proxyUrl != "":
    let proxy = newProxy(url = proxyUrl)
    result = newHttpClient(proxy = proxy)
  else:
    result = newHttpClient()

  var userAgent = getEnv("USER_AGENT", "")
  if userAgent.len == 0:
    userAgent = USER_AGENT

  result.headers = newHttpHeaders({
    "User-Agent": userAgent,
    "Accept-Language": "en-US,en;q=0.5",
  })

proc queryHtml(query: string, start = 0): string =
  var client = newProxyHttpClient()
  let q = encodeQuery({"q": query, "start": $start})
  let url = SEARCH_URL & "?" & q
  result = client.getContent(url)

iterator search*(query: string, maxResults = 10): SearchResult =
  ## Iterator over each result that search the given `query` string
  ## using Google. Return `maxResults` items at most.
  runnableExamples:
    for result in search("nim", 2):
      echo result.url & " " & result.title & " " & result.snippet

  var total = 0
  while total < maxResults:
    let html = queryHtml(query, total)
    let xml = parseHtml(newStringStream(html))

    let items = xml.querySelectorAll("div.g")
    if len(items) == 0:
      break

    for item in items:
      var sr: SearchResult
      for a in item.querySelectorAll("a"):
        sr.url = a.attr("href")
        break
      if sr.url.len < 10:
          continue

      for h3 in item.querySelectorAll("h3"):
        sr.title = h3.innerText()
        break

      let snippets = item.querySelectorAll("div>div>span>span")
      sr.snippet = ""
      for snip in snippets:
        sr.snippet &= $snip.innerText()

      yield sr

      total += 1
      if total >= maxResults:
        break

proc hits*(query: string): int =
  ## Search the given query string using Google and return the number of hits.
  runnableExamples:
    doAssert hits("nim-lang") > 0

  let html = queryHtml(query)
  let xml = parseHtml(newStringStream(html))
  let results = xml.querySelectorAll("div#result-stats")
  for stats in results:
    for match in stats.innerText().findAll(re"[\d,.]+"):
      return parseInt(match.replace(re","))

proc distance*(term1, term2: string): float =
  ## Return the Normalized Google Distance (NGD) between two search terms.
  ## Result is roughly in between 0 and ∞. It can be slightly negative.
  ##
  ## Notice: The NGD is not a metric.
  ##
  ## More details:
  ## https://en.wikipedia.org/wiki/Normalized_Google_distance
  runnableExamples:
    doAssert distance("nim-lang", "pascal") > 0.0

  let
    term1Hits = log10(float(hits(term1)))
    term2Hits = log10(float(hits(term2)))
    unionHits = log10(float(hits(&"\"{term1}\" \"{term2}\"")))
    indexPages = hits("the")
    termsPerPage = 1000
    logN = log10(float(indexPages * termsPerPage))
    numerator = max([term1Hits, term2Hits]) - unionHits
    denominator = logN - min([term1Hits, term2Hits])
  return numerator / denominator

when isMainModule:
  import std/wordwrap

  var args = commandLineParams()
  var query: string
  if len(args) == 0:
    echo "Google search tool"
    echo ""
    echo "Usage: googlesearch <query key> [<total results>]"
    quit()

  query = args[0]

  var total: int
  if len(args) >= 2:
    total = parseInt(args[1])
  else:
    total = 10

  proc wrap(s: string, maxLineWidth = 78, initialIndent = ""): string =
    initialIndent & wrapWords(s, maxLineWidth, newline = "\L" & initialIndent)

  var i = 0
  for result in search(query, total):
    i += 1
    var id = fmt"{i}/{total}"
    echo fmt"{id:<6}  {result.url}"
    echo fmt"        {result.title}"
    echo wrap(result.snippet, 70, "        ")
  echo $i & " results."
