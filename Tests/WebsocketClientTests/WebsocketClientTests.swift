import XCTest
@testable import WebsocketClient

final class WebsocketClientTests: XCTestCase {
    func testAsync() async throws {
        var received = 0
        let websocket = Websocket(url: URL(string: "wss://echo.websocket.org/")!) { data in
            let message = String(decoding: data, as: UTF8.self)
            XCTAssert(message == "Hello world!" || message.hasPrefix("Request served by"))
            received += 1
        }
        
        try await websocket.sendAsync("Hello world!")
        try await websocket.sendAsync("Hello world!")
        try await websocket.sendAsync("Hello world!")
        
        try? await Task.sleep(nanoseconds: 1 * 1000000000)
        XCTAssert(received == 4)
    }
    
    func testCallbacks() async throws {
        var received = 0
        let websocket = Websocket(url: URL(string: "wss://echo.websocket.org/")!) { data in
            let message = String(decoding: data, as: UTF8.self)
            XCTAssert(message == "Hello world!" || message.hasPrefix("Request served by"))
            received += 1
        }
        
        var sent = 0
        websocket.send("Hello world!") { error in
            sent += 1
        }
        
        websocket.send("Hello world!") { error in
            sent += 1
        }
        
        websocket.send("Hello world!") { error in
            sent += 1
        }
        
        try? await Task.sleep(nanoseconds: 1 * 1000000000)
        XCTAssert(sent == 3 && received == 4)
    }
}
