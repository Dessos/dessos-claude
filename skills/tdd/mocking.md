# When to Mock

Mock at **system boundaries** only:
- External APIs (exchange, Kafka, external data feeds)
- Database (prefer test DB or SQLite where possible)
- Time (`freezegun` or `unittest.mock.patch("time.time")`)
- Randomness (seed or patch)
- Network I/O

Don't mock:
- Your own classes/modules
- Internal collaborators within the same package
- Anything you control

## Designing for Mockability

1. **Dependency injection** -- pass external dependencies in rather than creating them internally. Use constructor parameters or fixture-provided instances.

2. **Protocol-style interfaces** -- define `typing.Protocol` for external boundaries. Each protocol method is independently mockable, no conditional logic in test setup.

```python
class ExchangePort(Protocol):
    async def submit_order(self, order: Order) -> OrderResult: ...
    async def cancel_order(self, order_id: str) -> bool: ...

# Production: CcxtBroker implements ExchangePort
# Tests: FakeExchange implements ExchangePort
```

3. **Paper broker pattern** -- this project already has `PaperBroker` as a test double for the exchange. Use it rather than mocking CCXT directly.
