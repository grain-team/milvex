# Changelog

## [0.11.0](https://github.com/grain-team/milvex/compare/v0.10.2...v0.11.0) (2026-04-30)


### Features

* Implements support for partial_updates ([2b5a909](https://github.com/grain-team/milvex/commit/2b5a9094489f0762d189c02f34184ba79ede1848))

## [0.10.2](https://github.com/grain-team/milvex/compare/v0.10.1...v0.10.2) (2026-03-25)


### Bug Fixes

* Mint adapter has slightly different errors ([3acebf1](https://github.com/grain-team/milvex/commit/3acebf188c7044d8de211befd7d9ddc8b496e82e))

## [0.10.1](https://github.com/grain-team/milvex/compare/v0.10.0...v0.10.1) (2026-03-25)


### Bug Fixes

* Fix retries for errors that kill-connections ([eb37f28](https://github.com/grain-team/milvex/commit/eb37f28060d5cc252f509674c2443be48cb36a18))

## [0.10.0](https://github.com/grain-team/milvex/compare/v0.9.2...v0.10.0) (2026-03-23)


### Features

* Added retry mechanism ([5711aeb](https://github.com/grain-team/milvex/commit/5711aeb529d9f02bec0881ce36888d7f734bbafb))


### Bug Fixes

* Merging with the app configs ([124f4bb](https://github.com/grain-team/milvex/commit/124f4bb67fcd18a19f93b853ed302ff7ddfea83a))
* Passing the settings correctly ([6e69911](https://github.com/grain-team/milvex/commit/6e69911ad577379de34404a97d9d335a26fd55c1))

## [0.9.2](https://github.com/grain-team/milvex/compare/v0.9.1...v0.9.2) (2026-03-23)


### Bug Fixes

* Add bounded error_type to the error telemetries ([e5ea579](https://github.com/grain-team/milvex/commit/e5ea57923208912499011a5ece7bcbee404e91ed))

## [0.9.1](https://github.com/grain-team/milvex/compare/v0.9.0...v0.9.1) (2026-03-23)


### Bug Fixes

* Do not RPC call describe_collection if using schemas ([f591209](https://github.com/grain-team/milvex/commit/f591209cb39472a6823638b9ede52a1852a55126))

## [0.9.0](https://github.com/grain-team/milvex/compare/v0.8.0...v0.9.0) (2026-03-18)


### Features

* add offset, grouping, and misc params to hybrid search ([f87208a](https://github.com/grain-team/milvex/commit/f87208ae36d1893fe026eba6ec4691dbe7c58983))
* add offset, grouping, and misc params to vector search ([116d8fe](https://github.com/grain-team/milvex/commit/116d8fecb90f3d79d23d37f4f257de186acf54d9))
* Adds support to scalar indexes ([b48f2c0](https://github.com/grain-team/milvex/commit/b48f2c03751fd8bdb889c437b328db94e51e8a20))

## [0.8.0](https://github.com/grain-team/milvex/compare/v0.7.0...v0.8.0) (2026-03-16)


### Features

* Implement filter templates ([31700e4](https://github.com/grain-team/milvex/commit/31700e48db233d7eb8817d4dd527db6068f5313f))
* Implements Highlighting support ([f4f9dbf](https://github.com/grain-team/milvex/commit/f4f9dbf9e6bb7953bb248598d8a7b0ba3b4e908f))


### Bug Fixes

* Fixed doctor ([cea7f1d](https://github.com/grain-team/milvex/commit/cea7f1df4bd7b26dd0cbad0a5fbbc9f927e52378))
* Fixed merge ([564d70d](https://github.com/grain-team/milvex/commit/564d70d71481f578bdbb831f85cfe05ed3dcdeb5))

## [0.7.0](https://github.com/grain-team/milvex/compare/v0.6.0...v0.7.0) (2026-03-12)


### Features

* Adds support to decay ranker ([4a0653e](https://github.com/grain-team/milvex/commit/4a0653e4f4746b96f87cc248e291b46563eaf7d6))

## [0.6.0](https://github.com/grain-team/milvex/compare/v0.5.3...v0.6.0) (2026-03-04)


### Features

* Adds Telemetry ([ed4840d](https://github.com/grain-team/milvex/commit/ed4840dfe4397dae8f6cf568af02617fb0220a8b))

## [0.5.3](https://github.com/grain-team/milvex/compare/v0.5.2...v0.5.3) (2026-02-10)


### Bug Fixes

* Fix socket leak on Gun Adapter ([6c56e73](https://github.com/grain-team/milvex/commit/6c56e739d53aa7197f3fae5cedbcd9ecb03bbf1a))

## [0.5.2](https://github.com/grain-team/milvex/compare/v0.5.1...v0.5.2) (2026-02-02)


### Bug Fixes

* Fixes healthcheck ([0f03f42](https://github.com/grain-team/milvex/commit/0f03f42b7adf71973f368537fa8b6ee72eba6acd))

## [0.5.1](https://github.com/grain-team/milvex/compare/v0.5.0...v0.5.1) (2026-01-28)


### Features

* Adds is_dynamic option to schema fields ([a1fcc2b](https://github.com/grain-team/milvex/commit/a1fcc2b9e20f39d71e5ce0a4a4b70879103fed87))
* Adds support to timestampz fields ([8ec9106](https://github.com/grain-team/milvex/commit/8ec910646fe6f3b1794c2abd85f44fbab3c68311))


### Bug Fixes

* Adds text to allowed dynamic fields ([ebf346b](https://github.com/grain-team/milvex/commit/ebf346b3d03509d03ff7a550119150ef1f105c84))

## [0.5.0](https://github.com/grain-team/milvex/compare/v0.4.2...v0.5.0) (2026-01-06)


### Features

* add BM25 full-text search support ([d33c532](https://github.com/grain-team/milvex/commit/d33c532eb8949ab1429d78b561ae1491af69b162))


### Bug Fixes

* Fixed bm25 validation ([805a7a3](https://github.com/grain-team/milvex/commit/805a7a32260732cfa25f1accc355e04433f9180e))
* Fixed multi-vector mapping ([f412281](https://github.com/grain-team/milvex/commit/f41228138407dcf2620b5b5129b2ed2183e4d7f4))
* Fixed multiple index creation ([e9efbd4](https://github.com/grain-team/milvex/commit/e9efbd403b804810b6be09333747a00ac4578dfd))
* Fixes sparse-fields creation when its a struct ([f900faa](https://github.com/grain-team/milvex/commit/f900faaaf847090ee372134e81494c9c3386da4a))
* Parsing fector array correctly ([0d0e663](https://github.com/grain-team/milvex/commit/0d0e66351c17c38a5db97174f7ea5e65debf0ce4))

## [0.4.2](https://github.com/grain-team/milvex/compare/v0.4.0...v0.4.2) (2025-12-19)


### Features

* Add support to multi-vectors ([b76d4d0](https://github.com/grain-team/milvex/commit/b76d4d0a0644da031e196ce7d8670b927922dd86))


### Bug Fixes

* Fixed cacert config ([6af8635](https://github.com/grain-team/milvex/commit/6af8635ec5ec169ae788750ae1df9a0ff34d52d9))
* Fixed dynamic fields parsing ([2df934b](https://github.com/grain-team/milvex/commit/2df934bdad89011d6eeef946ee71ca4a30454769))
* Fixed license ([6377161](https://github.com/grain-team/milvex/commit/63771611c2292f6d4c9ddef89863b157c66dc9b1))
* Handling unmatched events from gun and allowing adapter change ([#7](https://github.com/grain-team/milvex/issues/7)) ([0dcc0bb](https://github.com/grain-team/milvex/commit/0dcc0bb995e94efd941cfb3a891faba94116f8a9))

## [0.4.0](https://github.com/ycastorium/milvex/compare/v0.3.1...v0.4.0) (2025-12-17)


### Features

* Added support to keyed searches ([20b1147](https://github.com/ycastorium/milvex/commit/20b1147071588b4b32100041e2d35ab493ffabe9))


### Bug Fixes

* Auto ID should not filter out passed in ids ([f4f9876](https://github.com/ycastorium/milvex/commit/f4f98767422ee2ae5212bb6fd56acdfdf8a625df))
* Improve disconnection handling ([1d40643](https://github.com/ycastorium/milvex/commit/1d40643c3335c10596d2178d2140b0f75da7c72e))
* Redacting the GRPC Channel Inspect ([66205cf](https://github.com/ycastorium/milvex/commit/66205cf2ccc69a50d9f15706050284e90579d7b7))

## [0.3.1](https://github.com/ycastorium/milvex/compare/v0.3.0...v0.3.1) (2025-12-08)


### Bug Fixes

* Fixed index creation ([b68e7a5](https://github.com/ycastorium/milvex/commit/b68e7a584f76cbe761f0028ff7ce58510cc7340a))

## [0.3.0](https://github.com/ycastorium/milvex/compare/v0.2.0...v0.3.0) (2025-12-08)


### Features

* Adds simple migration and prefix to collections ([d313a75](https://github.com/ycastorium/milvex/commit/d313a758cc7343bbb341e58835f81206bd2d92a9))


### Bug Fixes

* Fixed credo warning ([a496c1b](https://github.com/ycastorium/milvex/commit/a496c1b4e6f58d87f1e067c6eb631a9ad4532cb8))

## [0.2.0](https://github.com/ycastorium/milvex/compare/v0.1.0...v0.2.0) (2025-12-04)


### Features

* Implements Collection DSL using Spark ([96c00ad](https://github.com/ycastorium/milvex/commit/96c00ad36acfd4d7e1b0ce10f5c211e3ff6ff6bc))
* Integrate collection types into the api ([e501145](https://github.com/ycastorium/milvex/commit/e501145181098d09e0464bdd2ef3f596081dcafa))

## 0.1.0 (2025-12-04)


### Features

* Created Configuration module ([92e28f7](https://github.com/ycastorium/milvex/commit/92e28f77081c9fcda67a20be62583ca6a69b440a))
* Created Connection Handler Module ([1740c1a](https://github.com/ycastorium/milvex/commit/1740c1a3982f74cd6f04999ae0e8a91953408b60))
* Created RPC Wrapper ([b0b6f0b](https://github.com/ycastorium/milvex/commit/b0b6f0b6d63b6b7039b90e737078bd28809afa22))
* Creating Basic Errors ([35fcf62](https://github.com/ycastorium/milvex/commit/35fcf626aad60ac32fa8be3884a792bb37c92929))
* Implemented Schema ([3bdbadb](https://github.com/ycastorium/milvex/commit/3bdbadb53e4676ecb6054bb4ce2b52bcb3602f92))
* Implementing Basic Client ([11ed41d](https://github.com/ycastorium/milvex/commit/11ed41da610ddb7047f959517df8b0d2f7514e4c))
* Implementing data-parsing ([153f46d](https://github.com/ycastorium/milvex/commit/153f46d1e5abff2e0bd46ea5cd15de813a5d40f4))
* Preparing Release ([3bfb593](https://github.com/ycastorium/milvex/commit/3bfb593bc1ecac608cfcd8c7e052a67a16fa0c0b))


### Bug Fixes

* Fixed credo and dialyzer errors ([7176355](https://github.com/ycastorium/milvex/commit/71763557e6c57101e534d7a1baea8902883731a6))
* Redact sensitive fields from the Milvex.Connection in case of inspection ([91f041f](https://github.com/ycastorium/milvex/commit/91f041f63c6bb4d27338faf68e7dacd190eb217c))


### Continuous Integration

* Added github actions ([033fe63](https://github.com/ycastorium/milvex/commit/033fe63c6382e8cd616be1c2621dfdf4c99c7d4a))
