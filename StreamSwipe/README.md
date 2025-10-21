# StreamSwipe

StreamSwipe is a SwiftUI iPhone application that helps couples build a joint watchlist by swiping through shows sourced from major streaming platforms. It layers an intuitive Tinder-style swipe deck on top of a configurable discovery pipeline that can be backed by any catalog API (RapidAPI, Watchmode, uNoGS, etc.).

## Highlights
- **Shared discovery experience** – Swipe right to add a title to a shared queue, left to skip. Actions are persisted through the `StreamingCatalogClient` abstraction.
- **Live catalog support** – The `StreamingCatalogClient.live` implementation wraps a REST API and uses environment variables to inject the base URL and API token.
- **Rich filters** – Narrow results by streaming service, show type, genres, release year and runtime directly inside the app.
- **Offline-friendly mocks** – A `StreamingCatalogClient.mock` variant ships with curated sample data so the UI can be previewed in Xcode without network calls.

## Project structure
```
StreamSwipe/
├── StreamSwipeApp.swift          # App entry point
├── ContentView.swift             # Hosts the swipe deck and filter sheet
├── Models/
│   ├── DiscoveryFilters.swift    # Filter state shared across the app
│   └── Show.swift                # Core models + enum definitions
├── Services/
│   └── StreamingCatalogClient.swift  # API abstraction + mock data helpers
├── Utilities/
│   ├── GenreCatalog.swift        # Lightweight actor-backed genre cache
│   └── ImageLoader.swift         # Async image loading with caching hooks
└── Views/
    ├── FilterView.swift          # Filter form UI
    ├── ShowCardView.swift        # Hero card with gradients + metadata
    └── SwipeDeckView.swift       # Gesture-driven swipe stack
```

## Connecting to a live catalog
1. Choose a provider that exposes platform availability (e.g. [Watchmode](https://www.watchmode.com), [uNoGS](https://rapidapi.com/unogs/api/unogsng/), or [Reelgood](https://rapidapi.com)) and expose an aggregator endpoint that returns show metadata.
2. Implement a lightweight API facade that maps the provider's JSON response to the `Show` model. You can either swap `StreamingCatalogClient.live` with your own implementation or point its base URL to a serverless proxy that performs the mapping.
3. Supply the credentials at runtime:
   - `STREAMSWIPE_BASE_URL` – Base REST endpoint (e.g. `https://your-proxy.vercel.app`).
   - `STREAMSWIPE_API_KEY` – API token or bearer credential understood by your proxy.
   - `STREAMSWIPE_ENABLE_WRITE` – Set to `true` if your backend supports persisting save/skip actions.

```
STREAMSWIPE_BASE_URL=https://your-proxy.example
STREAMSWIPE_API_KEY=super-secret-token
STREAMSWIPE_ENABLE_WRITE=true
```

4. Extend the proxy to aggregate availability across Netflix, Hulu, Prime Video, Disney+, Max, and Apple TV+. The `DiscoveryFilters` structure sends the following query items: `services`, `genres`, `types`, `min_year`, and `max_runtime`.

## Pairing flow idea
- Invite your partner by generating a deep link that shares an account token (beyond the scope of this sample).
- As each person swipes, the backend can compute mutual saves and highlight them in the UI.

## Running in Xcode
1. Create a new **iOS App** project named `StreamSwipe` in Xcode (Swift + SwiftUI).
2. Replace the generated `App` and `ContentView` files with the versions included here and drop the remaining folders (`Models`, `Services`, `ViewModels`, `Views`, `Utilities`) into the Xcode project.
3. Build & run on iOS 16+ to preview the experience. The mock client will serve data automatically until environment variables are supplied.

## Next steps
- Connect sign-in + shared watchlist persistence (e.g. Firebase, Supabase, PocketBase).
- Add push notifications when both partners save the same title.
- Build a widget that surfaces the current mutual pick of the day.
- Extend `StreamingCatalogClient` with background refresh and caching.
