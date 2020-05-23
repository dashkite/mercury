failure = do ({codes, message} = {}) ->

  codes =

    "unexpected status": ({expect, response}) ->
      "unexpected status: #{response.status}"

    "not ok": ({response}) ->
      "status is not ok: #{response.status}"

    "unsupported media type": ({response})->
      "unsupported media type: #{response.headers['content-type']}"

  (code, context) ->
    message = codes[code] context
    error = new Error "Mercury: #{message}"
    error.context = context
    error.status = context.response?.status
    error


export default failure
