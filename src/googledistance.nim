import googlesearch

when isMainModule:
  import os
  import strformat
  let args = commandLineParams()
  if len(args) < 2:
    echo "Google distance tool"
    echo ""
    echo "Usage: googledistance <term 1> <term 1>"
    quit()

  let term1 = args[0]
  let term2 = args[1]

  echo "The Normalized Google Distance (NGD) of ", term1, " and ", term2, " is:"
  let dist = distance(term1, term2)
  echo fmt"    {dist:.3f}"
