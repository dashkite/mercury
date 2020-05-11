# Mercury
_Combinators for making HTTP requests._

Mercury works a lot like SuperAgent, except via function composition instead of chaining.

```coffeescript
import {flow} from "panda-garden"
import {property} from "panda-parchment"
import {use, resource, parameters, headers, http, Fetch, json} from "@dashkite/mercury"

PublicAPI =
  search:
    flow [
      use Fetch.client {fetch}
      resource "https://api.publicapis.org/entries"
      parameters (query) -> query
      headers accept: "application/json"
      http.get
      expect 200
      json
      property "json"
    ]
```

The result is an async function that we can call to make the request:

```
{entries} = await PublicAPI.search title: "cat", category: "animals"
assert entries
```

Using composition means Mercury is effectively infinitely extensible. For example, Mercury comes with functions to support Panda Sky-based APIs to construct the request and check the response. 

```coffeescript
import {flow} from "panda-garden"
import {property} from "panda-parchment"
import {use, resource, parameters, headers, http, Sky, json} from "@dashkite/mercury"

register = flow [
  use Sky.client {fetch}
  Sky.discover "https://links.dashkite.com"
  resource "profiles"
  content from ({profile}) -> profile
  http.post
  json
  property "json"
]
```

Since these are just functions, we can easily add new features. For example, we could write a simple function that adapts the `http` combinators to check the URL against an application cache.

Mercury combinators compose to async functions, which means they can be reused within other compositions. For example, we might create an initialization combinator that we can reuse, to ensure a set of resources is available for subsequent requests. This is harder to do with chaining.

## Installation

```
npm i @dashkite/mercury
```

Use with your favorite bundler.

## API

### Basic Combinators

#### use client

TBD

#### events function

TBD

#### resource name

TBD

#### url text

TBD

#### base text

TBD

#### query builder

TBD

#### template text

TBD

#### parameters builder

TBD

#### headers object

TBD

#### method name

TBD

#### content builder

TBD

#### data function

TBD

#### accept type

TBD

#### media type

TBD

#### expect codes

TBD

#### request method

TBD

#### http.*

TBD

#### cache requestor

TBD

#### json

TBD

#### text

TBD

#### blob

TBD

### Fetch Combinators

#### client options

TBD

### Sky Combinators

#### client options

TBD

#### discover url

TBD

### Zinc Combinators

#### grant

TBD

#### authorize

TBD

### Confidential Combinators

#### encrypt

TBD

#### decrypt

TBD

#### sign

TBD

### 