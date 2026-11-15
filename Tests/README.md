Run the standalone Micropub regression checks with a current Swift toolchain (tested with Swift 6.2.1):

```sh
swift test
bash Tests/test-micropub-state.sh
```

These checks cover S256 PKCE against RFC 7636, form encoding, HTTPS discovery identity, authenticated media-endpoint discovery and failure fallback, plus pending authorization storage and cleanup. Network responses and keychain storage are controlled fixtures; no live blog is contacted.

The iOS app uses CryptoKit. The Swift package uses swift-crypto only for the Linux test target; it does not change the app's Xcode dependencies.

An iOS build and device check are still needed to verify the browser return and keychain integration:

1. Add an external blog by entering a bare domain, and repeat with an explicit HTTP address that redirects to HTTPS. Confirm the consent screen uses the final HTTPS identity and an S256 challenge.
2. Approve the connection, return to Sunlit and publish a photo to a server advertising a separate media endpoint. Confirm the upload uses that endpoint and the post uses the primary Micropub endpoint.
3. Repeat with a server that does not provide `q=config`, confirming that the previous upload fallback is retained.
4. Deny a connection or sign out during setup, confirming that pending state is cleared and no completed connection is restored afterward.
