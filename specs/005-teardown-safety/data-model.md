# Data model

No exported type changes. `BDDResult`, `TestContext`, `BDDTest`, `Language` and `FailFast` keep their constructors and fields. A failed teardown is reported through the existing tasty `Result`; when a step already failed, that step's failure stays the reported reason.
