# WebsocketClient
Swift library for using WebSockets.

### Example code:
```swift
// Import library
import WebsocketClient

...

// Open connection
let websocket = Websocket(url: URL(string: "wss://echo.websocket.org/")!) { data in
    print(String(decoding: data, as: UTF8.self))
}

// Send messages
// - with completion handler
websocket.send("Message 1") { error in
    guard let error = error else { return }
    print(error)
}

// - using async function
try await websocket.sendAsync("Message 2")

// - encode object to JSON
struct Request: Encodable {
    var field: String
}
try await websocket.sendAsync(Request(field: "value"))

try? await Task.sleep(nanoseconds: 1 * 1000000000)

// you can close connection manually, however it should automatically close when `Websocket` object is deinitialized
...
```

### Sending messages
`Data`, `String` and any `Encodable` object can be send using `.send` or `.sendAsync`
