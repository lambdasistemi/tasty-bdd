# Functions model

| name | arguments | type | change |
|---|---|---|---|
| `whenAction` | `f`, `test` | `Functor f => (m t -> f (m t)) -> BDDTest m t q -> f (BDDTest m t q)` | replaces the export `when`, same type |

No other exported function, class method or instance changes its name, arguments, constraints or result type.
