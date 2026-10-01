# Modules model

No module is added or removed and no dependency direction changes. `Test.Tasty.Bdd` keeps owning both `IsTest` instances; `Test.BDD.LanguageFree` keeps owning the free interpreter and `BDDResult`. Any release-sequencing helper stays unexported inside the module that uses it.
