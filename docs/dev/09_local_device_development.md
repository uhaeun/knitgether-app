# Local Device Development

KnitGether has separate shared Xcode schemes for the common local development modes.

## Schemes

- `KnitGether Local Offline`: runs without `KNITGETHER_API_BASE_URL`, so the app uses local repositories and does not need the server.
- `KnitGether Local Simulator`: points the app at `http://127.0.0.1:3000/api/v1`, which works from iOS Simulator because simulator localhost is the Mac.
- `KnitGether Local Device`: points the app at `http://haeun.local:3000/api/v1`, which resolves to this Mac for physical iPhone testing.

If `haeun.local` does not resolve on the current network, use the Mac Wi-Fi IP address in `KNITGETHER_API_BASE_URL` for the `KnitGether Local Device` scheme.

## Starting the Local API

From the repository root:

```bash
cd server
docker compose up -d
npm run start:dev
```

The iPhone and Mac must be on the same Wi-Fi network. macOS may ask whether Node can accept incoming network connections; allow it for physical device testing.

## Running on a Physical iPhone

1. Open `KnitGether.xcodeproj`.
2. Select the `KnitGether Local Device` scheme.
3. Select the physical iPhone as the run destination.
4. Run the app from Xcode.
5. When iOS asks for local network permission, allow it.

For simulator-only API work, use `KnitGether Local Simulator`. For UI work that does not need the API, use `KnitGether Local Offline`.
