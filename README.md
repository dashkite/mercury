# Mercury
_Combinators for making HTTP requests._

Mercury works a lot like SuperAgent, except via function composition instead of chaining.

```coffee
import * as _ from "@dashkite/joy"
import * as m from "@dashkite/mercury"

PublicAPI =
  search:
    _.flow [
      m.request [
        m.url "https://api.publicapis.org/entries"
        m.query
        m.method "get"
        m.headers accept: "application/json"
        m.expect.status [ 200 ]
      ]
      m.response [ $.json ]
      _.get "json"
    ]
```

The result is an async function that we can call to make the request:

```coffeescript
{entries} = await PublicAPI.search
  title: "cat"
  category: "animals"
```

Using composition means Mercury is trivially extensible. For example, [Mercury Sky](https://github.com/dashkite/mercury-sky) comes with functions to support Panda Sky-based APIs to construct the request and check the response.

Since these are just functions, we can easily add new features. For example, we could write a simple function that adapts the `http` combinators to check the URL against an application cache.

Mercury combinators compose to async functions, which means they can be reused within other compositions. For example, we might create an initialization combinator that we can reuse, to ensure a set of resources is available for subsequent requests. This is harder to do with chaining.

## Installation

```
npm i @dashkite/mercury
```

Use with your favorite bundler or import directly in the browser.

## API

Mercury provides two top-level combinators:

- `request`, which takes an array of combinators to specify the request
- `response`, which takes an array of combinators for processing the response

Both combinators take a [daisho][] datastructure that may be manipulated using [Katana][] operators.

The `response` combinator returns a promise for an object describing the request and response.

[daisho]: https://github.com/dashkite/katana#daisho-data-structure
[Katana]: https://github.com/dashkite/katana

### Request Combinators

Request combinators may take an argument or implicitly read from the daisho stack.

| Combinator    | Arguments             | Description                                                  |
| ------------- | --------------------- | ------------------------------------------------------------ |
| base          | URL                   | The base URL, used in conjunction with `path` to construct the full URL. |
| path          | URL path              | The path of the URL, relative to the base URL.               |
| template      | URL template          | The [URL template](https://tools.ietf.org/html/rfc6570) to be expanded to generate the URL. |
| parameters    | object                | The parameters to use to expand the URL template. Not be confused with `query`. |
| url           | URL                   | The ultimate URL of the request.                             |
| query         | object                | The search parameters to be appended to the URL.             |
| method        | text                  | The method name (ex: GET, PUT, …) for the request. Will be converted to uppercase for you. |
| content       | any                   | The content body of the request. Takes a string or a value, which will be converted into a string using its `toString` method, except for arrays and objects, which are converted into JSON. |
| urlencoded    | object                | The content body, formatted as a URL encoded form.           |
| headers       | object                | The headers of the request.                                  |
| accept        | text                  | The accept header.                                           |
| media         | text                  | The content-type header.                                     |
| authorize     | text                  | The authorization header.                                    |
| cache         | text                  | The named CacheStorage object to use in processing the request. |
| expires       | number (milliseconds) | The expiration for cached responses.                         |
| expect.ok     | -                     | Expect an OK response (200 range).                           |
| expect.status | array                 | The status codes to expect (that will not throw).            |
| expect.media  | text                  | The content-type of the response. Use with accept.           |

### Response Combinators

| Combinator | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| json       | The result of parsing the response body as JSON.             |
| text       | The response body as plain text.                             |
| blob       | The response body as [raw data](https://developer.mozilla.org/en-US/docs/Web/API/Blob). |

Combinators from outside of Mercury may use additional properties.

### Use Outside The Browser

When using Mercury in Node, you will need to install Fetch and Request globally.

```coffeescript
import fetch from "node-fetch"

globalThis.fetch ?= fetch
global.Request ?= fetch.Request

```

If you want to use the `cache` combinator, you will also need to install `caches` globally:

```coffeescript
import { caches } from 'cache-polyfill'
globalThis.caches ?= caches
```

### Errors

When a Mercury combinator throws an exception, the error will contain additional information, if applicable. If there’s a response, it will contain `response` and `status` properties. If the request does not yet have a corresponding response, these will be undefined.

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
