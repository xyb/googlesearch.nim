# googlesearch.nim
Nim library for scraping google search results

## Installation

The best way to install the library is by using [nimble](https://github.com/nim-lang/nimble):

    nimble install googlesearch

## Usage

This is a simple example:
```nim
import googlesearch

for i, result in search("nim", 2):
    echo i + 1, "/", 2, "  ", result.url
    echo "     ", result.title
    echo "     ", result.snippet[0..70], "..."
```

Output:
```
1/2  https://en.wikipedia.org/wiki/Nim_(programming_language)
     Nim (programming language) - Wikipedia
     Nim (formerly named Nimrod) is an imperative, general-purpose, multi-pa...
2/2  https://nim-lang.org/
     Nim Programming Language
     Nim is a statically typed compiled systems programming language. It com...
```

### Command-line tool

This library includes a command-line tool:
```
$ googlesearch
Google search tool

Usage: googlesearch <query key> [<total results>]
```

You can simply use it search infos:
```
$ googlesearch "nim packages" 2
1/2     https://nimble.directory/
        Nim package directory
        Developer? Search for packages or jump directly to a package page. Nim
        Package Directory generates and hosts documentation for packages.
        Package ...
2/2     https://github.com/nim-lang/packages
        nim-lang/packages: List of packages for Nimble - GitHub
        Nim packages. name - The name of the package, this should match the
        name in the package's nimble file. url - The url from which to
        retrieve the package. method - The method that should be used to
        retrieve this package. tags - A list of tags describing this package.
        description - A description of this package.
2 results.
```

You may want to do complex serch like this:
```
$ googlesearch '"nim libray" wrapper -gpl site:github.com' 20
```
