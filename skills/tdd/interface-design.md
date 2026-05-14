# Interface Design for Testability

1. **Accept dependencies, don't create them** -- testable vs hard to test.

```python
# Hard to test -- creates its own dependency
class Engine:
    def __init__(self):
        self.broker = CcxtBroker()  # locked to production

# Testable -- accepts dependency
class Engine:
    def __init__(self, broker: ExchangePort):
        self.broker = broker  # inject PaperBroker in tests
```

2. **Return results, don't produce side effects** -- testable vs hard to test.

```python
# Hard to test -- side effect only
def process_signal(signal):
    send_order_to_exchange(signal.to_order())

# Testable -- returns result
def process_signal(signal) -> Order:
    return signal.to_order()  # caller decides what to do
```

3. **Small surface area** -- fewer methods = fewer tests needed, fewer params = simpler test setup.
