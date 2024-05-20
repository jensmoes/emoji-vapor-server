# Emoji Server using Vapor

A server example providing random emojis using [Swift OpenAPI](https://github.com/apple/swift-openapi-generator).

It is purposefully strict about input so that different responses can be triggered depending on the input.

## How to run

To build and run locally:
```console
% swift run
```

## Usage

Can be queried locally using `curl`:
```console
% curl http://localhost:8080/api/emoji
{
  "emoji" : "🍎",
  "source" : "Server"
}
```

Submissions can be made by posting to the same endpoint with a JSON body:
```json
{
    "emoji": "🦾",
    "source": "Jens"
}
```

