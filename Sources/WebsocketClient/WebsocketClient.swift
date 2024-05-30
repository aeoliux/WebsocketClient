// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// Websocket client
public class Websocket: NSObject, URLSessionWebSocketDelegate {
    private var websocket: URLSessionWebSocketTask?
    private var onReceive: (_ data: Data) -> ()
    private(set) public var closed: Bool = false
    
    /// Initializes a new and starts websocket client
    /// - Parameters:
    ///   - url: URL address
    ///   - onReceive: callback which is executed when server send a message, takes `Data` as parameter
    ///
    /// - Returns: `Websocket` object instance
    public init(url: URL, onReceive: @escaping (_ data: Data) -> ()) {
        self.onReceive = onReceive
        super.init()
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.websocket = session.webSocketTask(with: url)
        self.websocket?.resume()
        self.receive()
    }
    
    deinit {
        self.close()
    }
    
    func receive() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.websocket?.receive { result in
                do {
                    let message = try result.get()
                    switch message {
                    case .data(let data):
                        self?.onReceive(data)
                    case .string(let str):
                        if let data = str.data(using: .utf8) {
                            self?.onReceive(data)
                        }
                    @unknown default:
                        print("Unknown message type")
                    }
                    
                    (self?.closed ?? false) ? nil : self?.receive()
                } catch {
                    self?.websocket?.cancel()
                }
            }
        }
        
        DispatchQueue.main.async(execute: workItem)
    }
    
    /// Encodes object into JSON and sends it to the server
    ///
    /// - Parameter body: `Encodable` object
    public func sendAsync<T: Encodable>(_ body: T) async throws {
        let encoded = try JSONEncoder().encode(body)
        try await self.sendAsync(encoded)
    }
    
    /// Encodes object into JSON and sends it to the server
    ///
    /// - Parameters:
    ///   - body: `Encodable` object
    ///   - completionHandler: callback which takes `Error?` as a parameter. If the parameter is not `nil`, the error has occured
    public func send<T: Encodable>(_ body: T, completionHandler: @escaping (_ error: Error?) -> ()) {
        DispatchQueue.main.async {
            do {
                let encoded = try JSONEncoder().encode(body)
                self.send(encoded, completionHandler: completionHandler)
            } catch {
                completionHandler(error)
            }
        }
    }
    
    /// Sends message as `Data` to the server
    ///
    /// - Parameter message: message as `Data`
    public func sendAsync(_ message: Data) async throws {
        try await self.websocket?.send(URLSessionWebSocketTask.Message.data(message))
    }
    
    /// Sends message as `Data` to the server
    ///
    /// - Parameters:
    ///   - message: message as `Data`
    ///   - completionHandler: callback which takes `Error?` as a parameter. If the parameter is not `nil`, the error has occured
    public func send(_ message: Data, completionHandler: @escaping (_ error: Error?) -> ()) {
        self.websocket?.send(URLSessionWebSocketTask.Message.data(message), completionHandler: completionHandler)
    }
    
    /// Sends message as `String` to the server
    /// - Parameter message: message as `String`
    public func sendAsync(_ message: String) async throws {
        try await self.websocket?.send(URLSessionWebSocketTask.Message.string(message))
    }
    
    /// Sends message as `String` to the server
    /// - Parameters:
    ///   - message: message as `String`
    ///   - completionHandler: callback which takes `Error?` as a parameter. If the parameter is not `nil`, the error has occured
    public func send(_ message: String, completionHandler: @escaping (_ error: Error?) -> ()) {
        self.websocket?.send(URLSessionWebSocketTask.Message.string(message), completionHandler: completionHandler)
    }
    
    /// Closes connection
    public func close() {
        guard !self.closed else { return }
        
        self.websocket?.cancel()
        self.closed = true
    }
}
