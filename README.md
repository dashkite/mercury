# Mercury
_Combinators for making HTTP requests._

Mercury works a lot like SuperAgent, except via function composition instead of chaining.

```coffeescript
import {flow} from "panda-garden"
import {property} from "panda-parchment"
import {cast} from "@dashkite/katana"
import {use, Fetch, url, query, accept, request, json} from "@dashkite/mercury"

PublicAPI =
  search:
    flow [
      use Fetch.client {mode: "cors"}
      url "https://api.publicapis.org/entries"
      cast query, [ property "data" ]
      accept "application/json"
      request
      expect.status [ 200 ]
      expect.media "application/json"
      json
      property "json"
    ]
```

The result is an async function that we can call to make the request:

```coffeescript
{entries} = await PublicAPI.search
  title: "cat"
  category: "animals"
```

Using composition means Mercury is effectively infinitely extensible. For example, [Mercury Sky](https://github.com/dashkite/mercury-sky) comes with functions to support Panda Sky-based APIs to construct the request and check the response.

Since these are just functions, we can easily add new features. For example, we could write a simple function that adapts the `http` combinators to check the URL against an application cache.

Mercury combinators compose to async functions, which means they can be reused within other compositions. For example, we might create an initialization combinator that we can reuse, to ensure a set of resources is available for subsequent requests. This is harder to do with chaining.

## Installation

```
npm i @dashkite/mercury
```

Use with your favorite bundler.

## API

### Context Specification

| Property   | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| base       | The base URL, used in conjunction with `path` to construct the full URL. |
| path       | The path of the URL, relative to the base URL.               |
| template   | The [URL template](https://tools.ietf.org/html/rfc6570) to be expanded to generate the URL. |
| parameters | The parameters to use to expand the URL template. Not be confused with `query`. |
| url        | The ultimate URL of the request.                             |
| query      | The search parameters to be appended to the URL.             |
| method     | The method name (ex: GET, PUT, …) for the request.           |
| body       | The content body of the request.                             |
| headers    | The headers of the request.                                  |
| response   | The response to the request.                                 |
| json       | The result of parsing the response body as JSON.             |
| text       | The response body as plain text.                             |
| blob       | The response body as [raw data](https://developer.mozilla.org/en-US/docs/Web/API/Blob). |

Combinators from outside of Mercury may use additional properties.

### Combinators

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

#### path text

Sets the path for the request. This tacitly sets the URL by resolving the path relative to the base.

#### url text

Set the request URL.

#### template text

Set the URL template for generating the URL.

#### parameters object

Expand the template with the given object. Tacitly sets the URL to the resulting expansion.

#### query object

Set the query (search parameters) for the URL.

#### method name

Set the method name for the request, ex: “get”.

#### content value

Set the content (body) of the request to the given value. If the value is not a string, it’s converted to a string using `JSON.stringify`.

#### headers object

Set the headers for the request.

#### accept type

Set the `accept` header for the request and verify it against the `content-type` of the response.

#### media type

Set the `content-type` for the request.

#### authorize value

Set the `authorization` header to the given value.

#### request

Send the request based on the current request context and await the result, adding it to the context as the `response` property.

#### cache requestor

Maintain a local in-memory cache which is checked before sending the request. The cache is based on the request URL and method, so these need to have already been set.

#### expect.status codes

Check the response status against the array of codes and throw if there’s no match.

```coffeescript
expect.status [ 200, 204 ]
```

#### expect.ok

Check the response status to ensure it’s within the range of success status codes (200-299).

#### expect.media value

Check the response content type to ensure it matches the given value. (This should correspond to the accept value.)

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

#### data builder

Takes the `data` property of the request context and pass it into the given builder function. Omit this if you want to build up the result using the context directly. Useful in combination with the `property` combinator, from the [Panda Garden](https://github.com/pandastrike/panda-garden) module, and the `cast` combinator from the [Dashkite Katana](https://github.com/dashkite/katana) module.

```coffeescript
cast query, [ data property "description" ]
```

#### Fetch.client options

Process the request context using the Fetch API. Options:

- `fetch`: (optional) the Fetch implementation function to use
- `mode`: (optional) set the `mode` option for the Fetch client

```coffeescript
use Fetch.client mode: "cors"
```

### Errors

When a Mercury combinator throws an exception, the error will contain the request context as the `context` property. If there’s a response, it will also contain `response` and `status` properties. If the request does not yet have a corresponding response, these will be undefined. Unexpected errors (ex: attempting to use a malformed URL) will not include the request context.

#### error.context

Contains the request context at the point the exception was thrown.

#### error.response

Convenience for:

```coffeescript
error.context && error.context.response
```

Undefined if request does not have a corresponding response.

#### error.status

Convenience for:

```coffeescript
error.response && error.response.status
```

Undefined if request does not have a corresponding response.
