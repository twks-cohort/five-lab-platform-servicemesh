#!/usr/bin/env bats

@test "evaluate twdps.io ingress" {
  run bash -c "curl https://httpbin.${CLUSTER}.cohortscdi-five.com/status/418"
  [[ "${output}" =~ "-=[ teapot ]=-" ]]
}

@test "evaluate twdps.io certificate" {
  run bash -c "curl --cert-status -v https://httpbin.${CLUSTER}.cohortscdi-five.com/status/418"
  [[ "${output}" =~ "SSL certificate verify ok" ]]
}
