import SwiftUI
import SafariServices

public struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionStore = SubscriptionStore.shared
    @State private var webURL: URL?

    public init() {}

    public var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            heroArtwork

                            Text("Premium Access")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            benefits
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    subscriptionFooter
                        .frame(height: 200)
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
//                        .font
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.0))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close subscription")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await subscriptionStore.restorePurchases()
                    }
                } label: {
                    Text("Restore")
                }
                    .foregroundStyle(.white)
                .disabled(subscriptionStore.isLoading || subscriptionStore.isPurchasing)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await subscriptionStore.loadProduct()
        }
        .alert("Subscription", isPresented: errorAlertPresented) {
            Button("OK", role: .cancel) {
                subscriptionStore.errorMessage = nil
            }
        } message: {
            Text(subscriptionStore.errorMessage ?? "")
        }
        .sheet(isPresented: webSheetPresented) {
            if let webURL {
                SafariView(url: webURL)
            }
        }
    }

    private func footerHeight(for height: CGFloat) -> CGFloat {
        min(max(height * 0.30, 238), 270)
    }

    private var subscriptionFooter: some View {
        VStack(spacing: 0) {
            Button {
                Task {
                    if await subscriptionStore.purchase() {
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if subscriptionStore.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                    }
                }
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(red: 0.04, green: 0.55, blue: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 32)
            .disabled(subscriptionStore.isPurchasing || subscriptionStore.isLoading)

            Button {
                Task {
                    if await subscriptionStore.purchaseLifetime() {
                        dismiss()
                    }
                }
            } label: {
                Group {
                    if subscriptionStore.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Lifetime - \(subscriptionStore.lifetimeProduct?.displayPrice ?? "Unavailable")")
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 32)
            .padding(.top, 10)
            .disabled(subscriptionStore.lifetimeProduct == nil || subscriptionStore.isPurchasing || subscriptionStore.isLoading)

            HStack(spacing: 18) {
                Button("Terms of Use") {
                    webURL = URL(string: "https://sites.google.com/view/sonquoctri/terms-of-use")
                }
                Text("|")
                Button("Privacy Policy") {
                    webURL = URL(string: "https://sites.google.com/view/sonquoctri/privacy-policy")
                }
            }
            .font(.body)
            .foregroundStyle(Color.white.opacity(0.62))
            .padding(.top, 18)
        }
        .padding(.bottom, 5)
        .background(Color.black)
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { subscriptionStore.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    subscriptionStore.errorMessage = nil
                }
            }
        )
    }

    private var webSheetPresented: Binding<Bool> {
        Binding(
            get: { webURL != nil },
            set: { isPresented in
                if !isPresented {
                    webURL = nil
                }
            }
        )
    }

    private var heroArtwork: some View {
        Image("girl")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 280, alignment: .top)
            .clipped()
            .frame(maxWidth: .infinity)
            .padding(.top, 0)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 22) {
            SubscriptionBenefit(
                icon: "map.fill",
                title: "Live Tracking & Smart Alerts",
                subtitle: "Track your devices in real-time with instant alerts."
            )
            SubscriptionBenefit(
                icon: "airpodspro",
                title: "Expose Hidden Devices",
                subtitle: "Detect hidden devices nearby and stay secure."
            )
            SubscriptionBenefit(
                icon: "bell.fill",
                title: "3-Day Free Trial",
                subtitle: "Unlock all premium features for \(subscriptionStore.weeklyProduct?.displayPrice ?? "the store price")/week. Cancel Anytime"
            )
        }
        .padding(.top, 18)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ viewController: SFSafariViewController, context: Context) {}
}

private struct SubscriptionBenefit: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

//#Preview {
//    NavigationStack {
//        SubscriptionView()
//    }
//}
