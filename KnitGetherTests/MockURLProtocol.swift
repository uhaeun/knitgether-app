import Foundation

final class MockURLProtocol: URLProtocol {
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let requestHandlerHeader = "X-MockURLProtocol-Handler-ID"
    private static let handlersLock = NSLock()
    private static var requestHandlers: [String: RequestHandler] = [:]

    static func makeSession(
        requestHandler: @escaping RequestHandler
    ) -> URLSession {
        let handlerID = UUID().uuidString
        handlersLock.lock()
        requestHandlers[handlerID] = requestHandler
        handlersLock.unlock()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = [requestHandlerHeader: handlerID]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let handlerID = request.value(forHTTPHeaderField: Self.requestHandlerHeader),
            let requestHandler = Self.requestHandler(for: handlerID)
        else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
    }

    private static func requestHandler(for handlerID: String) -> RequestHandler? {
        handlersLock.lock()
        defer { handlersLock.unlock() }
        return requestHandlers[handlerID]
    }
}
