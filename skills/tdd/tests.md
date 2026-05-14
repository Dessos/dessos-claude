# Good and Bad Tests

## Good Tests (integration-style, test through real interfaces)

```python
def test_order_rejected_when_position_exceeds_limit(engine, risk_config):
    """Risk check blocks orders that would breach position limits."""
    risk_config.max_position_usd = 1000.0
    engine.submit_order(side="buy", size_usd=1500.0)
    assert engine.last_order_status == "rejected"
    assert "position limit" in engine.last_rejection_reason.lower()
```

Characteristics:
- Tests behavior callers care about
- Uses public API only (`submit_order`, `last_order_status`)
- Survives internal refactors
- Describes WHAT not HOW
- One logical assertion per test

## Bad Tests (implementation-detail tests)

```python
# BAD: Tests implementation details
def test_risk_check_calls_margin_model(mocker):
    mock_margin = mocker.patch("myproject.risk.margin_model.calculate")
    engine.submit_order(side="buy", size_usd=100.0)
    mock_margin.assert_called_once_with(100.0)
```

Red flags:
- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks on refactor without behavior change
- Test name describes HOW not WHAT

```python
# BAD: Bypasses interface to verify
def test_fill_updates_database(engine, db_session):
    engine.process_fill(fill_event)
    row = db_session.execute("SELECT * FROM fills WHERE ...").fetchone()
    assert row is not None

# GOOD: Verifies through interface
def test_fill_updates_position(engine):
    engine.process_fill(fill_event)
    position = engine.get_position("BTC/USDC")
    assert position.size == fill_event.size
```
