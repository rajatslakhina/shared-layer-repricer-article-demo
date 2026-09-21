# SharedLayerRepricer

**Shopify's move back to native is being read as "React Native lost." The more useful reading is that coding agents moved the cost curve under every *build once, share it* abstraction — so the number you should recompute is per-feature, not per-stack.**

This package is that computation, as runnable Swift. Give it a catalog of features
and a cost model, and it tells you, for each one, the **agent-assist level at which
building it twice natively becomes cheaper than keeping it in a shared layer** —
or that no such level exists.

Article: *(added after publish)*

---

## The finding

Run the bundled 12-feature catalog through the default cost model and **8 of 12
features never flip**, at any agent-assist level between 0% and 100%. Those eight
account for **72% of the shared-layer budget**.

Delete one term — the parity tax, the cost of verifying that two native
implementations still agree — and **all 12 flip**, with the checkout flow
crossing over at 75% assist.

That single term decides two thirds of the catalog, and it is the one term agent
assistance does not touch. Agents made authoring cheap. Nobody made *checking
that two authors agreed* cheap.

Measured on the checkout flow, going from 0% to 100% assist:

| Term | 0% assist | 100% assist | Change |
|---|---|---|---|
| Native build + ongoing authoring | 229.9 d | 86.5 d | **−62%** |
| Native parity verification | 41.0 d | 41.0 d | **0%** |

The parity tax goes from 15.1% of the native bill to 32.2% of it — not because it
grew, but because everything around it shrank.

### Flip order is not size order

| Feature | Build | Divergence | churn x parity | Verdict |
|---|---|---|---|---|
| Scan-to-cart camera | 28 d | 0.90 | 1.2 | flips at **10%** |
| Onboarding | 14 d | 0.70 | 0.8 | flips at **48%** |
| Settings | 10 d | 0.45 | 0.4 | flips at **66%** |
| Product detail page | 30 d | 0.55 | 5.6 | flips at **92%** |
| Checkout flow | 40 d | 0.25 | 17.1 | **never** |
| Pricing and tax rules | 24 d | 0.05 | 16.0 | **never** |

The largest feature in the catalog never flips. The first to flip is the fourth
largest — and the most divergent, meaning it was barely shared code to begin with.
Build size scales both strategies; the parity tax scales with churn and blast
radius. Teams rank the port backlog on the first axis and get surprised by the second.

---

## Using it

```swift
import SharedLayerRepricer

let report = RepriceReport.build(
    catalog: SampleCatalog.shoppingApp,
    assist: 0.6,                 // how much of your authoring an agent really does
    model: .default
)

print(report.flipped.count)      // features cheaper to build twice at 60% assist
print(report.neverFlipping.map(\.feature.name))

for verdict in report.orderedByFlipPoint {
    switch verdict.breakEven {
    case .alreadyNative:      print("\(verdict.feature.name): native from day one")
    case .flipsAt(let a):     print("\(verdict.feature.name): flips at \(a)")
    case .neverFlips:         print("\(verdict.feature.name): parity tax never clears")
    }
}
```

Defining your own catalog is four numbers per feature:

```swift
let feature = Feature(
    id: "checkout",
    name: "Checkout flow",
    nativeBuildDays: 40,       // engineer-days to build once, natively
    divergence: 0.25,          // 0...1 fraction that genuinely differs per platform
    parityCriticality: 0.95,   // 0...1 cost of silent drift between platforms
    changesPerYear: 18
)
```

---

## The load-bearing design decisions

**The parity term gets no agent discount — and that is an argument, not an oversight.**
`CostModel.authoringDiscountMax` applies to work an agent writes. `parityCostPerChange`
and `bridgeCostPerChange` deliberately sit outside it. If you disagree, change the
numbers: the model is the argument, and it is designed to be argued with.

**The shared strategy carries an undiscounted term too.** `bridgeCostPerChange` prices
release-train alignment and two teams agreeing on one API. A model where only the
native side has a fixed cost would be a strawman, so it doesn't.

**The break-even solver does not assume monotonicity.** The native strategy's build
and authoring terms both carry `authoringMultiplier(assist) x (1 + portFactor(assist))`,
which is quadratic in `assist`, so the shared-minus-native delta is a parabola and can
cross zero twice. A plain bisection over `[0, 1]` would return whichever root the
endpoints happened to bracket, or neither. `BreakEvenSolver` scans for sign changes on
a grid first, then bisects the **earliest** bracket, and a test asserts nothing crosses
before the reported root.

**Rejected alternatives**, so the choices are visible:

- *A single "is it shared?" boolean per feature.* Discarded: it hides divergence, which
  is the axis that decides three of the four flips here.
- *Monte Carlo over uncertain inputs.* Discarded: it produces a distribution where the
  useful artifact is an argument about one term. The sensitivity that matters is already
  a switch — set `parityCostPerChange` to zero and watch the answer invert.
- *Discounting future costs.* Discarded: a discount rate scales the ongoing terms of
  both strategies and would obscure the asymmetry rather than sharpen it.
- *`NaN` propagation on bad input.* Discarded: `Feature` maps non-finite values to zero.
  A NaN slider silently poisoning a whole portfolio report is worse than a visible zero.

---

## How to run it

```bash
git clone https://github.com/rajatslakhina/shared-layer-repricer-article-demo.git
cd shared-layer-repricer-article-demo
open Demo.xcodeproj     # pick any iOS Simulator, then Build & Run
```

One repo, one project, no second checkout. `Demo.xcodeproj` consumes the package in
this same directory through an `XCLocalSwiftPackageReference`, and the `Demo` scheme is
committed and shared, so it is selectable on a fresh clone. `Package.swift` declares only
a library product and a test target — deliberately **no** `.executableTarget`, because
running a package executable directly as an iOS app synthesizes a bundle identifier into
a per-checkout Xcode setting that is never committed, and it crashes on launch with
`__BKSHIDEvent__BUNDLE_IDENTIFIER_FOR_CURRENT_PROCESS_IS_NIL__` the moment that setting
is missing.

Headless:

```bash
swift build
swift test
```

---

## Verification status

Stated precisely rather than implied.

**Done:**

- `swift build` — clean, zero warnings (Swift 6.0.3, aarch64 Linux).
- `swift test` — **28 of 28 passing**, including the two load-bearing assertions
  (`testParityTaxIsInvariantToAgentAssist`, `testAuthoringTermsDoShrinkWithAgentAssist`),
  the non-monotonic-root case, and the empty-catalog, zero-horizon, NaN-input and
  out-of-range-clamp edge cases.
- `Demo.xcodeproj/project.pbxproj` — brace/paren balanced, all 20 object IDs valid
  24-character hex, every referenced ID defined, no orphans. `Demo.xcscheme` XML-validated.

**Not done, and not claimed:**

- **The demo was not launched on a Simulator, and `Demo/Screenshots/` is empty.** This ran
  as an unattended scheduled task, where `request_access` for Xcode/Simulator returns
  *"Computer-use access can't be approved during a scheduled run"* — called twice, per the
  tool's own one-time-retry flow, with the same result both times. There is no Mac shell in
  this environment either (the sandbox is Linux, so no `xcodebuild` or `simctl`), so the
  SwiftUI layer in `RepricerDemoView.swift` compiles on Linux only because
  `#if canImport(SwiftUI)` excludes it there. It has not been rendered.

The numbers in this README and in the article come from the library's real output, run
through the real test suite — that part is measured. The app launching is not.

---

## License

MIT
