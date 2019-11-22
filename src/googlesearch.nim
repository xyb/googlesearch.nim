import httpclient
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

proc `$`*(self: SearchResult): string =
  self.url & "\n  TITLE: " & self.title & "\n  SNIPPET: " & self.snippet

proc search*(query: string, num_results: int = 10): seq[SearchResult] =
  var client = newHttpClient()
  var start: int = 0
  while true:
    let q = encodeQuery({"q": query, "start": $start})
    let url = SEARCH_URL & "?" & q
    client.headers = newHttpHeaders({
      "User-Agent": USER_AGENT,
      "Accept-Language": "en-US,en;q=0.5",
    })
    let html = client.getContent(url)
    let xml = parseHtml(newStringStream(html))
    let links = xml.querySelectorAll("div.r")

    if len(links) == 0:
      break

    for link in links:
      var sr: SearchResult
      for a in link.querySelectorAll("a"):
        sr.url = a.attr("href")
        break
      for h3 in link.querySelectorAll("h3"):
        sr.title = h3.innerText()
        break
      result.add(sr)

    var n = start
    let snippets = xml.querySelectorAll("span.st")
    for snip in snippets:
      result[n].snippet = snip.innerText()
      n += 1

    if len(result) > num_results:
      result = result[0..<num_results]

    if len(result) == num_results:
      break

    start = len(result)

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

  proc wrap(s: string, maxLineWidth: int = 78,
      initialIndent: string = ""): string =
    initialIndent & wrapWords(s, maxLineWidth, newline = "\L" & initialIndent)

  let results = search(query, total)
  for i, result in results:
    var id = fmt"{i + 1}/{total}"
    echo fmt"{id:<6}  {result.url}"
    echo fmt"        {result.title}"
    echo wrap(result.snippet, 70, "        ")
  echo $len(results) & " results."
