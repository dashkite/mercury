failure = do ({codes, message} = {}) ->

  codes =

    "unexpected status": ({expect, response}) ->
      "unexpected status: #{response.status}"

    "not ok": ({response}) ->
      "status is not ok: #{response.status}"

    "no current profile": ->
      "Profile.current is undefined"

    "unsupported media type": ({response})->
      "unsupported media type: #{response.headers['content-type']}"

    "expected header": (header) ->
      "expected response header: #{header}"

  (code, args...) ->
    message = codes[code] args...
    new Error "Mercury: #{message}"

export default failure
