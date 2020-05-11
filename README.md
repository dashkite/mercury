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
      use Fetch.client {fetch, mode: "cors"}
      url "https://api.publicapis.org/entries"
      query property "data"
      headers accept: "application/json"
      http.get
      expect [ 200 ]
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
  use Sky.client "https://links.dashkite.com", {fetch}
  resource "profiles"
  content property "data"
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

Set the client to use for evaluating requests.

```coffeescript
use Fetch.client {fetch, mode: "cors"}
```

#### resource type

Set the resource type.

```coffeescript
resource "blog"
```

#### base text

Set the base URL for the request.

#### url text

Set the request URL. Resolved relative to the base URL if set.

#### template text

Set the URL template for generating the URL.

#### headers object

Set the headers for the request.

#### method name

Set the method name for the request.

#### accept type

Set the `accept` header for the request and verify it against the `content-type` of the response.

#### media type

Set the `content-type` for the request.

#### request

Send the request based on the current request context and await the result, adding it to the context.

#### http.*

Shortcuts for setting the method and invoking the request. Ex: `http.get` is equivalent to:

```coffeescript
method "get"
request
```

Supported methods are: get, put, delete, patch, post, options, and head.

#### cache requestor

Maintain a local in-memory cache which is checked before sending the request.

#### expect codes

Check the response status against the array of codes and throw if there’s no match.

```coffeescript
expect [ 200, 204 ]
```

#### Ok

Check the response status to ensure it’s within the range of success status codes (200-299).

#### json

Waits for the response body and parses it as JSON, adding the result to the request context as the property `json`.

```coffeescript
# grab the JSON body
json
# return the JSON result
property "json"
```

#### text

Waits for the response body as text and adds it to the request context as the property `text`.

#### blob

Waits for the response body as binary data and adds it to the request context as the property `blob`.

### Builder Combinators

Builder combinators build a result from the request context. This is useful when the value that is passed into the resulting request function has different facets corresponding to the query and content for the request. For example, suppose we have an component that has a `description` and a `form` property property that correspond to the query and content (body) of the request, respectively. We can bring this into the request contest like this:

```coffee
query data property "description"
content data property "form"
```

Sometimes we just want to pass a literal. In this case, you can use `wrap`:

```coffeescript
query wrap q: "Little Richard"
```

(Both `property` and `wrap` are from the Panda Garden module, but you may use any equivalent function.)

#### data builder

Takes the `data` property of the request context and pass it into the given builder function. Omit this if you want to build up the result using the context directly.

```coffeescript
query data property "description"
```

#### query builder

Set the query for the request URL to the result of applying the builder function.

#### parameters builder

Expand the template for the request with the result of applying the builder function and set the result of the expansion to the request URL.

#### content builder

Set the content (body) for the request to the result of applying the builder function.

### Events Combinators

#### events

Coming soon.

#### success

Coming soon.

#### failure

Coming soon.

### Fetch Combinators

#### client options

Process the request context using the Fetch API. Options:

- `fetch`: (optional) the Fetch implementation function to use
- `mode`: (optional) set the `mode` option for the Fetch client

```coffeescript
use Fetch.client mode: "cors"
```

### Sky Combinators

#### client url, options

Process the request using the Sky Client API. Accepts the discovery URL to use. Options:

- `fetch`: (optional) the Fetch implementation function 

### Zinc Combinators

#### grant

Coming soon.

#### authorize

Coming soon.

### Confidential Combinators

#### encrypt

Coming soon.

#### decrypt

Coming soon.

#### sign

Coming soon.

## Roadmap

- [ ] Implement `cache`.
- [ ] Implement and test Events combinators.
- [ ] Implement Zinc combinators. Ultimately, these belong in their own library. (Or: pass the profile in?)
- [ ] Implement Confidential combinators. Ultimately, these belong in their own library. (Or: pass confidential instance in?)