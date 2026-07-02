import SwiftUI
import AppFactoryKit

// Photo Enhancer — payments via native StoreKit 2 (no third-party SDK).
private enum Product {
    static let yearly = "enhancer_pro_yearly"
    static let weekly = "enhancer_pro_weekly"
}

@MainActor
enum PhotoEnhancerFactory {
    static func make() -> AppFactory {
        let config = AppFactoryConfiguration(
            appName: "Photo Enhancer",
            purchaseProvider: StoreKit2PurchaseProvider(productIDs: [Product.yearly, Product.weekly]),
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "sparkle.magnifyingglass",
                          title: "Sharpen Any Photo",
                          message: "Rescue soft, blurry or low-res photos — enhanced entirely on your device."),
                    .init(systemImage: "arrow.up.backward.and.arrow.down.forward",
                          title: "Upscale in One Tap",
                          message: "Boost resolution up to 4× and compare with a press-and-hold.")
                ],
                presentsPaywallOnFinish: true,
                accent: .purple
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock Photo Enhancer Pro",
                subheadline: "Full quality, no limits.",
                benefits: [
                    .init(systemImage: "arrow.up.backward.and.arrow.down.forward", title: "4× upscaling"),
                    .init(systemImage: "square.and.arrow.down", title: "Save full-resolution results"),
                    .init(systemImage: "infinity", title: "Unlimited enhancements"),
                    .init(systemImage: "nosign", title: "No ads")
                ],
                productIDs: [Product.yearly, Product.weekly],
                highlightedProductID: Product.yearly,
                ctaTitle: "Continue",
                dismissButtonDelay: 4,
                isDismissable: true,
                termsURL: URL(string: "https://zubeidhendricks.github.io/PhotoEnhancerUnblur/terms.html"),
                privacyURL: URL(string: "https://zubeidhendricks.github.io/PhotoEnhancerUnblur/privacy.html"),
                style: PaywallStyle(accent: .purple, heroSystemImage: "sparkle.magnifyingglass")
            )
        )
        return AppFactory(config)
    }
}

@main
struct PhotoEnhancerApp: App {
    @StateObject private var factory = PhotoEnhancerFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFactoryRoot(factory)
                .tint(.purple)
        }
    }
}
