import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import MicropubClient

final class MicropubClientTests: XCTestCase {
    private let endpoint = URL(string: "https://example.com/micropub?site=one")!
    private let me = URL(string: "https://example.com/")!
    private let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

    func testBareDomainsDefaultToHTTPSAndExplicitHTTPIsRetained() {
        XCTAssertEqual(MicropubClient.blogURL("  example.com/  ")?.absoluteString, "https://example.com/")
        XCTAssertEqual(MicropubClient.blogURL("http://example.com/")?.absoluteString, "http://example.com/")
        XCTAssertNil(MicropubClient.blogURL("ftp://example.com/"))
        XCTAssertNil(MicropubClient.blogURL("https://user:password@example.com/"))
        XCTAssertNil(MicropubClient.blogURL(""))
    }

    func testDiscoveryUsesTheFinalRedirectURLAsIdentity() {
        let entered = URL(string: "http://example.com/")!
        XCTAssertEqual(MicropubClient.discoveryURL(entered: entered, responseURL: me), me)
        XCTAssertEqual(MicropubClient.discoveryURL(entered: entered, responseURL: nil), entered)
    }

    func testS256ChallengeMatchesRFC7636() {
        XCTAssertEqual(MicropubClient.codeChallenge(for: verifier), "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }

    func testAuthorizationErrorsWithStateReachTheReturnHandler() {
        XCTAssertTrue(MicropubClient.isAuthorizationResponse(URL(string: "sunlit://micropub/?code=fixture-code&state=fixture-state")!))
        XCTAssertTrue(MicropubClient.isAuthorizationResponse(URL(string: "sunlit://micropub/?error=access_denied&state=fixture-state")!))
        XCTAssertFalse(MicropubClient.isAuthorizationResponse(URL(string: "sunlit://micropub/?error=access_denied")!))
        XCTAssertFalse(MicropubClient.isAuthorizationResponse(URL(string: "sunlit://micropub/fixture-token")!))
    }

    func testVerifiersAreFreshAndUseThePKCEAlphabet() {
        let verifiers = (0..<10).map { _ in MicropubClient.makeCodeVerifier() }
        XCTAssertEqual(Set(verifiers).count, 10)
        for verifier in verifiers {
            XCTAssertNotNil(verifier.range(of: "^[A-Za-z0-9_-]{43}$", options: .regularExpression))
        }
    }

    func testAuthorizationCarriesS256AndPreservesEndpointParameters() {
        let url = MicropubClient.authorizationURL(endpoint: endpoint, me: me, state: "fixture-state", verifier: verifier)
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        let values = Dictionary(uniqueKeysWithValues: query.map { ($0.name, $0.value!) })
        XCTAssertEqual(values["site"], "one")
        XCTAssertEqual(values["me"], me.absoluteString)
        XCTAssertEqual(values["state"], "fixture-state")
        XCTAssertEqual(values["scope"], "create delete")
        XCTAssertEqual(values["code_challenge_method"], "S256")
        XCTAssertEqual(values["code_challenge"], MicropubClient.codeChallenge(for: verifier))
        XCTAssertEqual(values["redirect_uri"], MicropubClient.redirectURI)
        XCTAssertEqual(values["client_id"], MicropubClient.clientID)
    }

    func testAuthorizationReplacesReservedParametersAndEncodesPlusSigns() {
        let endpoint = URL(string: "https://example.com/auth?state=old&code_challenge=old&tenant=a%2Bb")!
        let url = MicropubClient.authorizationURL(endpoint: endpoint, me: me, state: "a+b", verifier: verifier)
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(query.filter { $0.name == "state" }.map(\.value), ["a+b"])
        XCTAssertEqual(query.filter { $0.name == "code_challenge" }.count, 1)
        XCTAssertTrue(url.absoluteString.contains("state=a%2Bb"))
        XCTAssertTrue(url.absoluteString.contains("tenant=a%2Bb"))
    }

    func testTokenFormUsesTheSameVerifierAndEscapesTheAuthorizationCode() {
        let code = "fixture+code&x=1"
        let data = MicropubClient.tokenBody(code: code, me: me.absoluteString, verifier: verifier)
        let body = String(decoding: data, as: UTF8.self)
        let query = URLComponents(string: "https://example.com/?" + body)!.queryItems!
        let values = Dictionary(uniqueKeysWithValues: query.map { ($0.name, $0.value!) })
        XCTAssertEqual(values["code"], code)
        XCTAssertEqual(values["code_verifier"], verifier)
        XCTAssertEqual(values["me"], me.absoluteString)
        XCTAssertEqual(values["grant_type"], "authorization_code")
        XCTAssertTrue(body.contains("code=fixture%2Bcode%26x%3D1"))
    }

    func testInFlightLegacyAuthorizationCanFinishWithoutAVerifier() {
        let body = String(decoding: MicropubClient.tokenBody(code: "fixture-code", me: me.absoluteString, verifier: nil), as: UTF8.self)
        XCTAssertFalse(body.contains("code_verifier"))
    }

    func testConfigurationRequestUsesBearerAuthenticationAndPreservesRouting() {
        let request = MicropubClient.configurationRequest(endpoint: endpoint, token: "fixture-token")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fixture-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.url?.absoluteString, "https://example.com/micropub?site=one&q=config")
    }

    func testMediaEndpointDiscoveryUsesTheAdvertisedUploadURL() {
        assertMediaEndpoint(body: #"{"media-endpoint":"https://uploads.example.com/media"}"#, expected: "https://uploads.example.com/media")
    }

    func testRelativeMediaEndpointsResolveAgainstTheResponseURL() {
        assertMediaEndpoint(body: #"{"media-endpoint":"/media"}"#, expected: "https://example.com/media")
    }

    func testMissingMalformedOrFailedConfigurationKeepsTheLegacyFallback() {
        assertMediaEndpoint(body: "{}", expected: nil)
        assertMediaEndpoint(body: "invalid JSON", expected: nil)
        assertMediaEndpoint(body: #"{"media-endpoint":""}"#, expected: nil)
        assertMediaEndpoint(body: #"{"media-endpoint":"file:///tmp/upload"}"#, expected: nil)
        assertMediaEndpoint(body: #"{"media-endpoint":"https://uploads.example.com/media"}"#, status: 403, expected: nil)
        assertMediaEndpoint(body: "", error: URLError(.notConnectedToInternet), expected: nil)
    }

    private func assertMediaEndpoint(body: String, status: Int = 200, error: Error? = nil, expected: String?, file: StaticString = #filePath, line: UInt = #line) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ConfigurationResponse.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        ConfigurationResponse.body = Data(body.utf8)
        ConfigurationResponse.status = status
        ConfigurationResponse.error = error
        let finished = expectation(description: "Configuration response")
        MicropubClient.discoverMediaEndpoint(endpoint: endpoint, token: "fixture-token", session: session) { url in
            XCTAssertEqual(url?.absoluteString, expected, file: file, line: line)
            finished.fulfill()
        }
        wait(for: [finished], timeout: 2)
    }
}

private final class ConfigurationResponse: URLProtocol {
    static var body = Data()
    static var status = 200
    static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
