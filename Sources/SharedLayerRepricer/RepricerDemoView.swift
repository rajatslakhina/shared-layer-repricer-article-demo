#if canImport(SwiftUI)
import SwiftUI

/// Live view of the model: drag the agent-assist slider and watch which
/// features leave the shared layer — and which never do.
public struct RepricerDemoView: View {

    private let catalog: [Feature]
    private let model: CostModel

    @State private var assist: Double = 0.0

    public init(catalog: [Feature] = SampleCatalog.shoppingApp, model: CostModel = .default) {
        self.catalog = catalog
        self.model = model
    }

    private var report: RepriceReport {
        RepriceReport.build(catalog: catalog, assist: assist, model: model)
    }

    public var body: some View {
        let report = self.report
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Agent assist")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(assist.formatted(.percent.precision(.fractionLength(0))))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $assist, in: 0...1)
                            .accessibilityLabel("Agent assist level")

                        HStack(spacing: 18) {
                            metric("Build twice", "\(report.flipped.count)/\(catalog.count)")
                            metric("Never flip", "\(report.neverFlipping.count)")
                            metric("Best case", "\(Int(report.bestCaseTotal.rounded())) d")
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Cheapest option per feature") {
                    ForEach(report.orderedByFlipPoint) { verdict in
                        row(verdict)
                    }
                }
            }
            .navigationTitle("Shared vs. Native")
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline.monospacedDigit())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func row(_ verdict: FeatureVerdict) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verdict.feature.name).font(.body)
                Text(caption(for: verdict))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(verdict.nativeWins ? "NATIVE" : "SHARED")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(verdict.nativeWins ? Color.orange.opacity(0.22) : Color.blue.opacity(0.18),
                            in: Capsule())
        }
    }

    private func caption(for verdict: FeatureVerdict) -> String {
        switch verdict.breakEven {
        case .alreadyNative:
            return "native from the start"
        case .flipsAt(let value):
            return "flips at \(value.formatted(.percent.precision(.fractionLength(0)))) assist"
        case .neverFlips:
            return "parity tax never clears"
        }
    }
}

#Preview {
    RepricerDemoView()
}
#endif
