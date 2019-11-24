import httpclient
import os
import sequtils
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

proc queryHtml(query: string, start = 0): string =
  var client = newProxyHttpClient()
  let q = encodeQuery({"q": query, "start": $start})
  let url = SEARCH_URL & "?" & q
  client.headers = newHttpHeaders({
    "User-Agent": USER_AGENT,
    "Accept-Language": "en-US,en;q=0.5",
  })
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

    let links = xml.querySelectorAll("div.r")
    if len(links) == 0:
      break
    let snippets = xml.querySelectorAll("span.st")

    for (link, snip) in zip(links, snippets):
      var sr: SearchResult
      for a in link.querySelectorAll("a"):
        sr.url = a.attr("href")
        break
      for h3 in link.querySelectorAll("h3"):
        sr.title = h3.innerText()
        break
      sr.snippet = snip.innerText()

      yield sr

      total += 1
      if total >= maxResults:
        break

when isMainModule:
  import os
  import strformat
  import strutils
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
