# Feature-First Clean Architecture

Each feature should grow in this order:

- `domain`: entities, value objects, repository contracts, pure services.
- `application`: Riverpod providers, controllers, use cases, view models.
- `data`: models, mappers, local/remote data sources, repository implementations.
- `presentation`: screens and widgets only. No business rules.

Offline-first data should be modeled behind repository contracts. Local sources
are the default source of truth; remote sync can be added behind the same
interfaces later.
