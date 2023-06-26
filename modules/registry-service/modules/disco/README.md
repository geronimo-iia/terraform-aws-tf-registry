# Amazon API Gateway Terraform Discovery Module

This is a building-block module for publishing a discovery document for
[Terraform's service discovery protocol](https://www.terraform.io/docs/internals/remote-service-discovery.html)
at the root of an Amazon API Gateway REST API.

The module creates a shallow tree of resources to produce the
`/.well-known/terraform.json` path that Terraform expects, and then configures
method `GET` on that full path to return a static discovery document containing
a JSON serialization of the given `services` map.

The method is configured with a "MOCK" integration, so the static response
comes directly from API Gateway and does not depend on any backend services.
