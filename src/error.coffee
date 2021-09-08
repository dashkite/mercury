import * as M from "@dashkite/joy/metaclass"

class HTTPError extends Error

  constructor: (message, @response) ->
    super "Mercury: #{message}"

  M.mixin @::, [
    M.getter "status", -> @response.status
  ]

export { HTTPError as Error }