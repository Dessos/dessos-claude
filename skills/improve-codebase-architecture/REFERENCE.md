# Reference: Dependency Categories

## 1. In-process
Pure computation, in-memory state, no I/O. Always deepenable -- merge modules and test directly.

**Examples in this project**: PnL calculations, position sizing math, signal generation, event routing logic.

## 2. Local-substitutable
Dependencies with local test stand-ins (e.g., SQLite for PostgreSQL, PaperBroker for CCXT).

**Examples in this project**: PaperBroker substitutes for CcxtBroker, in-memory event bus for Kafka.

## 3. Remote but owned (Ports & Adapters)
Your own services across network boundary. Define port (interface) at module boundary. Deep module owns logic; transport is injected.

**Examples in this project**: Kafka producers/consumers, PostgreSQL persistence layer.

## 4. True external (Mock)
Third-party services you don't control. Mock at boundary.

**Examples (typical)**: third-party REST APIs, external data feeds, SaaS provider SDKs.

## Testing Strategy

**Replace, don't layer.** Old unit tests on shallow modules are waste once boundary tests exist -- delete them. Write new tests at deepened module's interface boundary. Tests assert on observable outcomes through public interface, not internal state.

## RFC Template

- **Problem** -- architectural friction, shallow/coupled modules, integration risk
- **Proposed Interface** -- signature, usage, what it hides
- **Dependency Strategy** -- which category, how handled
- **Testing Strategy** -- new boundary tests, old tests to delete, test environment needs
- **Implementation Recommendations** -- responsibilities, hidden details, interface contract, caller migration (NOT coupled to file paths)
