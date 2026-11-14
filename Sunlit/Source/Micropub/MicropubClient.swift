import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

enum MicropubClient {
    static let clientID = "https://sunlit.io/"
    static let redirectURI = "https://sunlit.io/micropub/redirect"

    static func blogURL(_ address: String) -> URL? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let qualified = trimmed.contains("://") ? trimmed : "https://" + trimmed
        return endpointURL(qualified)
    }

    static func endpointURL(_ address: String, relativeTo base: URL? = nil) -> URL? {
        guard let url = URL(string: address, relativeTo: base)?.absoluteURL,
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.fragment == nil else { return nil }
        return url
    }

    static func discoveryURL(entered: URL, responseURL: URL?) -> URL {
        return responseURL.flatMap { endpointURL($0.absoluteString) } ?? entered
    }

    static func makeCodeVerifier() -> String {
        return base64URL(Data((0..<32).map { _ in UInt8.random(in: .min ... .max) }))
    }

    static func codeChallenge(for verifier: String) -> String {
        return base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    static func authorizationURL(endpoint: URL, me: URL, state: String, verifier: String) -> URL {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        let parameters = [
            URLQueryItem(name: "me", value: me.absoluteString),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: "create delete"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge(for: verifier)),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        let names = Set(parameters.map(\.name))
        components.queryItems = (components.queryItems ?? []).filter { !names.contains($0.name) } + parameters
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url!
    }

    static func tokenBody(code: String, me: String, verifier: String?) -> Data {
        var parameters = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "me", value: me)
        ]
        if let verifier = verifier {
            parameters.append(URLQueryItem(name: "code_verifier", value: verifier))
        }
        var components = URLComponents()
        components.queryItems = parameters
        let form = components.percentEncodedQuery!.replacingOccurrences(of: "+", with: "%2B")
        return Data(form.utf8)
    }

    static func configurationRequest(endpoint: URL, token: String) -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = (components.queryItems ?? []).filter { $0.name != "q" } + [URLQueryItem(name: "q", value: "config")]
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func discoverMediaEndpoint(endpoint: URL, token: String, session: URLSession = .shared, completion: @escaping (URL?) -> Void) {
        session.dataTask(with: configurationRequest(endpoint: endpoint, token: token)) { data, response, error in
            guard error == nil,
                  let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode),
                  let data = data,
                  let configuration = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let address = configuration["media-endpoint"] as? String, !address.isEmpty else {
                completion(nil)
                return
            }
            completion(endpointURL(address, relativeTo: response.url ?? endpoint))
        }.resume()
    }

    private static func base64URL(_ data: Data) -> String {
        return data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
