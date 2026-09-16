import SwiftUI

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page = 0

    private let pages = OnboardingPage.allCases

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.13, blue: 0.29),
                    Color(red: 0.02, green: 0.09, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    onboardingFooter
                        .frame(height: min(max(geometry.size.height * 0.18, 136), 166))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var onboardingFooter: some View {
        VStack(spacing: 0) {
            Button {
                if page == pages.count - 1 {
                    hasCompletedOnboarding = true
                } else {
                    withAnimation(.easeInOut) {
                        page += 1
                    }
                }
            } label: {
                Text("Continue")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 384)
                    .frame(height: 64)
                    .background(Color(red: 0.91, green: 0.95, blue: 0.99))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)

            HStack(spacing: 12) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 18)
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            FeatureGrid(items: page.gridItems)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Spacer(minLength: 12)

            VStack(spacing: 12) {
//                Text(page.eyebrow)
//                    .font(.title3.weight(.semibold))
//                    .foregroundStyle(Color.white.opacity(0.58))

                Text(page.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.56))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct FeatureGrid: View {
    let items: [OnboardingFeature]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items) { item in
                VStack(spacing: 5) {
                    Spacer(minLength: 5)
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
//                            .aspectRatio(1, contentMode: .fit)
//                            .background(Color.white.opacity(0.1))
//                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                        if let badge = item.badge {
                            Text(badge)
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .overlay {
                                    Capsule().stroke(Color.white, lineWidth: 2)
                                }
                                .padding(10)
                        }
                    }

                    Text(item.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Spacer(minLength: 5)
                }
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

private struct OnboardingFeature: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let badge: String?
}

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case devices
    case features
    case steps

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .devices: return "Find My Devices Now"
        case .features: return "Powerful Features To"
        case .steps: return "Simple, Quick, Found"
        }
    }

    var title: String {
        switch self {
        case .devices: return "Track & Locate"
        case .features: return "Find It Fast"
        case .steps: return "Easy To Use"
        }
    }

    var subtitle: String {
        switch self {
        case .devices: return "Works with every Apple device and more. If it connects via Bluetooth, we can find it."
        case .features: return "Everything you need to find your devices now and keep them found."
        case .steps: return "Track down any lost Bluetooth device in seconds."
        }
    }

    var gridItems: [OnboardingFeature] {
        switch self {
        case .devices:
            return [
                .init(title: "AirPods", systemImage: "airpodspro", badge: nil),
                .init(title: "AirTag", systemImage: "smallcircle.filled.circle", badge: nil),
                .init(title: "Apple Watch", systemImage: "applewatch", badge: nil),
                .init(title: "Headphones", systemImage: "headphones", badge: nil),
                .init(title: "iPhone", systemImage: "iphone", badge: nil),
                .init(title: "iPad", systemImage: "ipad", badge: nil),
                .init(title: "Speakers", systemImage: "hifispeaker.fill", badge: nil),
                .init(title: "MacBook", systemImage: "laptopcomputer", badge: nil)
            ]
        case .features:
            return [
                .init(title: "Live Tracking", systemImage: "location.fill", badge: nil),
                .init(title: "Low Energy Detection", systemImage: "antenna.radiowaves.left.and.right", badge: nil),
                .init(title: "Signal Meter", systemImage: "chart.bar.fill", badge: nil),
                .init(title: "Device Sorting", systemImage: "line.3.horizontal.decrease.circle.fill", badge: nil),
                .init(title: "Direction Finder", systemImage: "arrow.turn.up.right", badge: nil),
                .init(title: "Device Map", systemImage: "map.fill", badge: nil),
                .init(title: "Proximity Alerts", systemImage: "bell.fill", badge: nil),
                .init(title: "Battery Status", systemImage: "battery.100percent.bolt", badge: nil)
            ]
        case .steps:
            return [
                .init(title: "Search", systemImage: "magnifyingglass", badge: nil),
                .init(title: "Observe signal strength", systemImage: "chart.bar.fill", badge: nil),
                .init(title: "Move around", systemImage: "figure.walk", badge: nil),
                .init(title: "Find your device", systemImage: "location.fill", badge: nil)
            ]
        }
    }
}

#Preview {
    OnboardingView()
}
