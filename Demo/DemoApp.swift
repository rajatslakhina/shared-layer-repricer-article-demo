import SwiftUI
import SharedLayerRepricer

/// Runnable host for `RepricerDemoView`.
///
/// Everything interesting lives in the `SharedLayerRepricer` package in this
/// same repo; this target exists so you can clone one repo, open
/// `Demo.xcodeproj`, hit Run, and drag the slider.
@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            RepricerDemoView()
        }
    }
}
