package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow = response {
    http_request.method == "GET"
    response := {
        "allowed": true,
        "headers": {"x-current-user": "OPA"}
    }
}

allow = response {
    http_request.method == "POST"
    http_request.headers[":scheme"] == "https"
    response := {
        "allowed": true,
        "headers": {"x-current-user": "OPA"}
    }
}
