# 0005: Riverpod for Flutter state management
Status: Accepted
Date: 2026-10-14

## Context
The Flutter app needs state management for:
- Multi-step onboarding flow (7 screens with complex state transitions)
- Form state with validation (personal details, document capture)
- Network calls with loading/error/success states
- Offline support with local caching
- Resume capability (persist and restore state)
- Authentication state (logged in/out, token refresh)
- Verification status tracking

Forces:
- Need compile-time safety (catch errors early)
- Need good testability (unit test business logic)
- Need automatic dependency injection
- Need to handle async operations cleanly
- Need to minimize boilerplate
- Need active maintenance and community support

## Decision
Use **Riverpod** (with code generation) for state management in the Flutter app.

Key implications:
- Use `@riverpod` annotation for state notifiers
- Use `ref.watch` for reactive UI updates
- Use `ref.read` for one-time reads (button taps, etc.)
- Use code generation to reduce boilerplate
- Organize providers by feature
- Use ProviderScope at app root
- Implement state as immutable classes (freezed or manual)

## Alternatives

1. **BLoC** — Business Logic Component
   - Pros: Well-established, explicit state transitions, good testing support
   - Cons: More boilerplate (events, states, blocs), verbose for simple cases
   
2. **Provider** — Official Flutter recommendation
   - Pros: Simple, built into Flutter
   - Cons: Runtime errors (no compile-time safety), harder to test, limited for complex state
   
3. **GetX** — All-in-one solution
   - Pros: Easy to learn, includes routing/di/state
   - Cons: Magic behavior, hard to test, controversial in community, less control
   
4. **Redux** — Predictable state container
   - Pros: Predictable, great dev tools
   - Cons: Too much boilerplate, overkill for this project

## Rationale

### Why Riverpod?
- **Compile-time safety**: Code generation catches errors at compile time (not runtime)
- **Less boilerplate**: Simpler than BLoC for most use cases
- **Automatic DI**: Dependencies are explicit and managed automatically
- **Async support**: Built-in support for async operations (FutureProvider, StreamProvider)
- **Testability**: Easy to mock providers in tests
- **State caching**: Built-in caching for network calls
- **Active maintenance**: Well-maintained by rrousselGit (same author as Provider)
- **Modern**: Uses latest Dart features (records, patterns, sealed classes)

### Why Code Generation?
- **Type safety**: Generated code is type-safe
- **Less boilerplate**: Auto-generate provider classes
- **Better DX**: Cleaner API, less manual wiring
- **Performance**: Optimized generated code

### Why Not BLoC?
- More boilerplate (events, states, blocs for each feature)
- Verbose for simple state (loading/data/error)
- Riverpod achieves similar testability with less code

### Why Not Provider?
- Runtime errors when provider not found
- Harder to test (need to pump widgets)
- Limited for complex async operations
- Riverpod is the evolution of Provider

## Consequences

### Benefits
- Compile-time safety reduces runtime errors
- Less boilerplate than BLoC
- Automatic dependency injection
- Excellent async operation support
- Built-in state caching
- Easy to test (mock providers)
- Active community and maintenance
- Good documentation

### Costs and Risks
- Code generation adds build step (slower builds)
- Newer than BLoC (smaller ecosystem, fewer examples)
- Learning curve for team unfamiliar with it
- Debugging generated code can be harder
- Breaking changes between major versions

### Mitigations
- Use build_runner efficiently (watch mode in development)
- Pin Riverpod version, follow migration guides
- Document provider patterns in README
- Pair programming for team learning
- Use devtools for debugging

## Implementation

### Folder Structure
```
mobile/lib/
├── core/
│   └── providers/          # Global providers (auth, theme, etc.)
├── features/
│   ├── auth/
│   │   ├── providers/      # Auth-specific providers
│   │   ├── models/         # State models
│   │   └── screens/        # UI
│   ├── personal_details/
│   │   ├── providers/
│   │   ├── models/
│   │   └── screens/
│   └── ...
```

### Provider Types
- **@riverpod** — State notifiers with methods (most common)
- **FutureProvider** — One-time async operations
- **StreamProvider** — Continuous async data
- **StateProvider** — Simple mutable state (use sparingly)

### State Models
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}
```

### Key Dependencies
- `flutter_riverpod` — State management
- `riverpod_annotation` — Annotations for code generation
- `riverpod_generator` — Code generation
- `freezed` — Immutable models (optional but recommended)
- `build_runner` — Build tool for code generation

### Development Workflow
1. Define provider with `@riverpod` annotation
2. Run `flutter pub run build_runner watch` (auto-regenerate)
3. Use provider in widgets with `ref.watch()`
4. Test by overriding providers

## Verification and Follow-up
- Verify code generation works correctly
- Test provider overrides in unit tests
- Verify state persistence across navigation
- Test async operations (loading/error/success)
- Document provider patterns and conventions
- Ensure build_runner doesn't slow down development significantly
- Record any limitations or issues encountered

## References
- Riverpod documentation: https://riverpod.dev/docs/getting_started
- Riverpod code generation: https://riverpod.dev/docs/concepts/providers/code_generation
- Migration from Provider: https://riverpod.dev/docs/migration_from_provider
