failure = do ({codes, message} = {}) ->

  codes =

    "unexpected status": (response) ->
      "unexpected status: #{response.status}"

    "not ok": (response) ->
      "status is not ok: #{response.status}"

    "unsupported media type": (response)->
      "unsupported media type: #{response.headers['content-type']}"

  (code, response) ->
    message = codes[code] response
    error = new Error "Mercury: #{message}"
    error.response = response
    error.status = response?.status
    error


export default failure
