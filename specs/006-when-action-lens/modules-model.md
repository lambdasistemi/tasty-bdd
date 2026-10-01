# Modules model

No module is added to or removed from the library and no dependency direction changes. `Test.BDD.Language` keeps owning `BDDTest` and its lenses. The compile-proof module belongs to a test suite, never to the library. `tools/check-api.sh` keeps owning the comparison against the 0.1.0.1 baseline, including the single accepted rename.
