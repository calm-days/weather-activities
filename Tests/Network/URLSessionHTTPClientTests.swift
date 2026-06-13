import XCTest
@testable import WeatherActivities

// MARK: - URLProtocol stub (Swift 6-safe)

final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    struct Stub { let data: Data?; let response: HTTPURLResponse?; let error: Error? }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _stub: Stub?

    static func set(_ s: Stub?) { lock.lock(); _stub = s; lock.unlock() }
    private static func get() -> Stub? { lock.lock(); defer { lock.unlock() }; return _stub }

    override class func canInit(with r: URLRequest) -> Bool { true }
    override class func canonicalRequest(for r: URLRequest) -> URLRequest { r }

    override func startLoading() {
        guard let s = Self.get() else { client?.urlProtocolDidFinishLoading(self); return }
        if let e = s.error {
            client?.urlProtocol(self, didFailWithError: e)
        } else {
            if let r = s.response {
                client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed)
            }
            if let d = s.data {
                client?.urlProtocol(self, didLoad: d)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

final class URLSessionHTTPClientTests: XCTestCase {

    private let url = URL(string: "https://example.com/data")!

    /// A small `Decodable & Sendable` payload to decode in success cases.
    private struct Payload: Decodable, Sendable, Equatable {
        let value: Int
        let label: String
    }

    private func makeClient() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    private func httpResponse(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    override func tearDown() {
        URLProtocolStub.set(nil)
        super.tearDown()
    }

    // MARK: - Success

    func test_get_200WithValidJSON_decodes() async throws {
        let json = #"{"value":42,"label":"hi"}"#
        URLProtocolStub.set(.init(data: Data(json.utf8), response: httpResponse(200), error: nil))

        let result: Payload = try await makeClient().get(url)
        XCTAssertEqual(result, Payload(value: 42, label: "hi"))
    }

    // MARK: - Server errors

    func test_get_http500_mapsToServerError() async {
        URLProtocolStub.set(.init(data: Data("{}".utf8), response: httpResponse(500), error: nil))

        await assertThrowsAppError(.server(statusCode: 500)) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    func test_get_http404_mapsToServerErrorWithCode() async {
        URLProtocolStub.set(.init(data: Data("{}".utf8), response: httpResponse(404), error: nil))

        await assertThrowsAppError(.server(statusCode: 404)) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    // MARK: - Connectivity errors

    func test_get_notConnected_mapsToOffline() async {
        URLProtocolStub.set(.init(data: nil, response: nil,
                                  error: URLError(.notConnectedToInternet)))

        await assertThrowsAppError(.offline) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    func test_get_networkConnectionLost_mapsToOffline() async {
        URLProtocolStub.set(.init(data: nil, response: nil,
                                  error: URLError(.networkConnectionLost)))

        await assertThrowsAppError(.offline) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    func test_get_timedOut_mapsToTimeout() async {
        URLProtocolStub.set(.init(data: nil, response: nil, error: URLError(.timedOut)))

        await assertThrowsAppError(.timeout) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    // MARK: - Decoding errors

    func test_get_malformedJSON_mapsToDecoding() async {
        let malformed = "{ this is : not json "
        URLProtocolStub.set(.init(data: Data(malformed.utf8), response: httpResponse(200), error: nil))

        await assertThrowsAppError(.decoding) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    func test_get_validJSONWrongShape_mapsToDecoding() async {
        // Valid JSON, but missing the required keys for `Payload`.
        let wrong = #"{"unexpected":true}"#
        URLProtocolStub.set(.init(data: Data(wrong.utf8), response: httpResponse(200), error: nil))

        await assertThrowsAppError(.decoding) {
            let _: Payload = try await self.makeClient().get(self.url)
        }
    }

    // MARK: - Assertion helper

    private func assertThrowsAppError(
        _ expected: AppError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("Expected to throw \(expected) but succeeded", file: file, line: line)
        } catch let error as AppError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected AppError.\(expected) but got \(error)", file: file, line: line)
        }
    }
}
