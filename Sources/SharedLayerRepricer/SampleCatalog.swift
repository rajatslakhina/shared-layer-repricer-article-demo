import Foundation

/// A twelve-feature catalog shaped like a real consumer shopping app.
///
/// The numbers are estimates, not measurements, and they are the *inputs* to
/// the argument rather than its evidence. What the article claims is a
/// property of the model's structure — that the parity term is invariant to
/// agent assistance — and that claim survives re-estimating every row here.
public enum SampleCatalog {

    public static let shoppingApp: [Feature] = [
        Feature(id: "checkout",  name: "Checkout flow",
                nativeBuildDays: 40, divergence: 0.25, parityCriticality: 0.95, changesPerYear: 18),
        Feature(id: "cart",      name: "Cart and promotions",
                nativeBuildDays: 26, divergence: 0.15, parityCriticality: 0.90, changesPerYear: 22),
        Feature(id: "search",    name: "Search and filters",
                nativeBuildDays: 34, divergence: 0.35, parityCriticality: 0.55, changesPerYear: 12),
        Feature(id: "pdp",       name: "Product detail page",
                nativeBuildDays: 30, divergence: 0.55, parityCriticality: 0.40, changesPerYear: 14),
        Feature(id: "onboarding", name: "Onboarding",
                nativeBuildDays: 14, divergence: 0.70, parityCriticality: 0.20, changesPerYear: 4),
        Feature(id: "auth",      name: "Auth and session",
                nativeBuildDays: 22, divergence: 0.20, parityCriticality: 0.85, changesPerYear: 6),
        Feature(id: "settings",  name: "Settings",
                nativeBuildDays: 10, divergence: 0.45, parityCriticality: 0.15, changesPerYear: 3),
        Feature(id: "orders",    name: "Order history",
                nativeBuildDays: 16, divergence: 0.20, parityCriticality: 0.50, changesPerYear: 5),
        Feature(id: "loyalty",   name: "Loyalty and points",
                nativeBuildDays: 20, divergence: 0.10, parityCriticality: 0.80, changesPerYear: 9),
        Feature(id: "address",   name: "Address book",
                nativeBuildDays: 12, divergence: 0.30, parityCriticality: 0.60, changesPerYear: 3),
        Feature(id: "camera",    name: "Scan-to-cart camera",
                nativeBuildDays: 28, divergence: 0.90, parityCriticality: 0.25, changesPerYear: 5),
        Feature(id: "pricing",   name: "Pricing and tax rules",
                nativeBuildDays: 24, divergence: 0.05, parityCriticality: 1.00, changesPerYear: 16)
    ]
}
