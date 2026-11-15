import Foundation

// Compile alongside the app's MicropubState.swift, without UIKit or a real keychain.
enum Settings {
    static var values: [String: Any] = [:]
    static var keychain: [String: String] = [:]
    static func object(forKey key: String) -> Any? { values[key] }
    static func setValue(_ value: Any?, forKey key: String) { values[key] = value }
    static func setSecureString(_ value: String, forKey key: String) { keychain[key] = value }
    static func getSecureString(forKey key: String) -> String? { keychain[key] }
    static func deleteSecureString(forKey key: String) { keychain.removeValue(forKey: key) }
}

enum BlogSettings {
    enum PublishingPurpose: String { case posts, checkIns }
}

MicropubState.save(state: "first", name: "example.com", purpose: .checkIns, verifier: "first-verifier", me: "https://example.com/")
MicropubState.save(state: "second", name: "other.example", verifier: "second-verifier", me: "https://other.example/")
precondition(MicropubState.lookupBlogName(from: "first") == "example.com")
precondition(MicropubState.publishingPurpose(from: "first") == .checkIns)
precondition(MicropubState.identity(from: "first") == "https://example.com/")
precondition(MicropubState.codeVerifier(from: "first") == "first-verifier")
precondition(MicropubState.codeVerifier(from: "second") == "second-verifier")
precondition(!(Settings.values.values.compactMap { $0 as? [String: String] }.flatMap { $0.values }).contains("first-verifier"))
precondition(MicropubState.lookupBlogName(from: "unknown") == nil)
precondition(MicropubState.codeVerifier(from: "unknown") == nil)

// Completing or denying one request must leave another pending request intact.
MicropubState.remove(state: "first")
precondition(MicropubState.lookupBlogName(from: "first") == nil)
precondition(MicropubState.codeVerifier(from: "first") == nil)
precondition(MicropubState.identity(from: "first") == nil)
precondition(MicropubState.publishingPurpose(from: "first") == .posts)
precondition(MicropubState.codeVerifier(from: "second") == "second-verifier")

// Delete by blog name clears every matching state and its verifier.
MicropubState.save(state: "third", name: "other.example", verifier: "third-verifier")
MicropubState.delete(blogName: "other.example")
precondition(MicropubState.lookupBlogName(from: "second") == nil)
precondition(MicropubState.codeVerifier(from: "second") == nil)
precondition(MicropubState.codeVerifier(from: "third") == nil)

// Logout clears pending keychain values before Settings removes its lookup tables.
MicropubState.save(state: "fourth", name: "example.com", verifier: "fourth-verifier", me: "https://example.com/")
MicropubState.clear()
precondition(Settings.keychain.isEmpty)
precondition(MicropubState.lookupBlogName(from: "fourth") == nil)
precondition(MicropubState.identity(from: "fourth") == nil)

// An authorization started by an older version remains readable.
MicropubState.save(state: "legacy", name: "example.com")
precondition(MicropubState.lookupBlogName(from: "legacy") == "example.com")
precondition(MicropubState.codeVerifier(from: "legacy") == nil)
precondition(MicropubState.identity(from: "legacy") == nil)
MicropubState.clear()
print("PASS Micropub pending-state storage, isolation, cleanup and legacy compatibility")
