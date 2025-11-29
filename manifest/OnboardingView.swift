import SwiftUI
import UserNotifications
import CoreLocation

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var notificationsGranted = false
    @State private var locationGranted = false

    var body: some View {
        TabView(selection: $currentPage) {
            // Screen 1: Welcome & Value Prop
            WelcomeScreen(currentPage: $currentPage)
                .tag(0)

            // Screen 2: Notifications Permission
            NotificationsPermissionScreen(isGranted: $notificationsGranted)
                .tag(1)

            // Screen 3: Location Permission
            LocationPermissionScreen(isGranted: $locationGranted)
                .tag(2)

            // Screen 4: App Overview
            AppOverviewScreen(
                onComplete: {
                    isOnboardingComplete = true
                }
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// MARK: - Screen 1: Welcome
struct WelcomeScreen: View {
    @Binding var currentPage: Int
    @State private var showTagline = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // App title - immediately visible
                Text(".manifest")
                    .font(.custom("Georgia-Bold", size: 36))
                    .foregroundColor(.black)
                    .padding(.bottom, 40)

                // Tagline - both lines fade in together
                Text("Connect your daily tasks")
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(showTagline ? 1 : 0)
                    .padding(.bottom, 14)

                Text("to your core values.")
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(showTagline ? 1 : 0)
            }

            Spacer()

            // Swipe indicator
            Text("Swipe to continue")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 56)
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            // Both lines fade in together after 0.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.8)) {
                    showTagline = true
                }
            }
        }
    }
}

// MARK: - Screen 2: Notifications Permission
struct NotificationsPermissionScreen: View {
    @Binding var isGranted: Bool
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Icon
                Image("alarm")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                // Title
                Text("Stay On Track")
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(.black)

                // Description
                Text("Get gentle reminders for your routines and tasks. You're in complete control—enable only what helps you.")
                    .font(.system(size: 17))
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                // Enable button
                Button(action: {
                    requestNotificationPermission()
                }) {
                    Text(isGranted ? "Notifications Enabled" : "Enable Notifications")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isGranted ? Color.green : Color.black)
                        .cornerRadius(12)
                }
                .disabled(isGranted || isRequesting)
                .padding(.horizontal, 32)
                .accessibilityLabel(isGranted ? "Notifications enabled" : "Enable notifications")
                .accessibilityHint(isGranted ? "" : "Allows the app to send you reminders for routines and tasks")

                // Skip button
                if !isGranted {
                    Button(action: {
                        // Just allow them to continue
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 40)

            // Swipe indicator
            Text("Swipe to continue")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 56)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func requestNotificationPermission() {
        isRequesting = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                isGranted = granted
                isRequesting = false
            }
        }
    }
}

// MARK: - Screen 3: Location Permission
struct LocationPermissionScreen: View {
    @Binding var isGranted: Bool
    @State private var isRequesting = false
    @StateObject private var locationManager = LocationPermissionManager()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Icon
                Image("sunrise2")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                // Title
                Text("See Your Day")
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(.black)

                // Description
                Text("Your location shows sunrise and sunset colors for your routines. It also helps with address suggestions for tasks.")
                    .font(.system(size: 17))
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                // Privacy note
                Text("Your location never leaves your device.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 16) {
                // Enable button
                Button(action: {
                    requestLocationPermission()
                }) {
                    Text(locationManager.isAuthorized ? "Location Enabled" : "Enable Location")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(locationManager.isAuthorized ? Color.green : Color.black)
                        .cornerRadius(12)
                }
                .disabled(locationManager.isAuthorized || isRequesting)
                .padding(.horizontal, 32)
                .accessibilityLabel(locationManager.isAuthorized ? "Location enabled" : "Enable location")
                .accessibilityHint(locationManager.isAuthorized ? "" : "Allows the app to show sunrise and sunset colors and provide address suggestions")

                // Skip button
                if !locationManager.isAuthorized {
                    Button(action: {
                        // Just allow them to continue
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 40)

            // Swipe indicator
            Text("Swipe to continue")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 56)
        }
        .background(Color(uiColor: .systemBackground))
        .onChange(of: locationManager.isAuthorized) { newValue in
            isGranted = newValue
        }
    }

    private func requestLocationPermission() {
        isRequesting = true
        locationManager.requestPermission()
        // Reset requesting after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRequesting = false
        }
    }
}

// MARK: - Screen 4: App Overview
struct AppOverviewScreen: View {
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Icon
                Image("stones")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .accessibility(label: Text("Balanced stones representing harmony and values"))
                    .padding(.bottom, 42)

                // Title
                Text("Four Simple Spaces")
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(.black)
            }
            .padding(.bottom, 46)

            // Feature highlights
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "sun.haze.fill",
                    isSystemIcon: true,
                    title: ".my routine",
                    description: "Design your ideal daily schedule"
                )

                FeatureRow(
                    icon: "checklist",
                    isSystemIcon: true,
                    title: ".to do list",
                    description: "Track tasks and appointments using a color coded smart list"
                )

                FeatureRow(
                    icon: "v.circle",
                    isSystemIcon: true,
                    title: ".my values",
                    description: "Define and activate a set of values that are important to you"
                )

                FeatureRow(
                    icon: "chart.bar.xaxis",
                    isSystemIcon: true,
                    title: ".analysis",
                    description: "See which values you serve most often"
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            // Get Started button
            Button(action: {
                onComplete()
            }) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 70)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Helper Views
struct FeatureRow: View {
    let icon: String
    let isSystemIcon: Bool
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon container - consistent 32x32 frame for all icons
            ZStack {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.black)
                } else {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.black)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.7))
            }
            .padding(.top, 4)

            Spacer()
        }
    }
}

// MARK: - Initial Values Selection View
struct InitialValuesSelectionView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedValues: Set<String> = []

    // 20 curated popular values
    let popularValues = [
        "Accountability", "Achievement", "Authenticity", "Balance",
        "Compassion", "Courage", "Creativity", "Family",
        "Freedom", "Gratitude", "Growth", "Health",
        "Honesty", "Integrity", "Kindness", "Learning",
        "Love", "Mindfulness", "Purpose", "Respect"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image("stones")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .accessibility(label: Text("Balanced stones"))
                            .padding(.top, 20)

                        Text("Choose Your Values")
                            .font(.custom("Georgia-Bold", size: 24))
                            .foregroundColor(.black)

                        Text("Select 3-5 values to activate")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .background(Color(uiColor: .systemBackground))

                    // Values list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(popularValues, id: \.self) { valueName in
                                InitialValueRow(
                                    valueName: valueName,
                                    isSelected: selectedValues.contains(valueName),
                                    onToggle: {
                                        if selectedValues.contains(valueName) {
                                            selectedValues.remove(valueName)
                                        } else {
                                            selectedValues.insert(valueName)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }

                    // Bottom buttons
                    VStack(spacing: 12) {
                        // Activate button
                        Button(action: {
                            activateSelectedValues()
                        }) {
                            Text("Activate \(selectedValues.count) Value\(selectedValues.count == 1 ? "" : "s")")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(selectedValues.count >= 3 && selectedValues.count <= 5 ? Color.black : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(selectedValues.count < 3 || selectedValues.count > 5)
                        .padding(.horizontal, 32)

                        // Browse all button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Browse All Values")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }

                        // Skip button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 20)
                    .background(Color(uiColor: .systemBackground))
                }
            }
        }
    }

    private func activateSelectedValues() {
        // Get the full Value objects from ValuesLibrary
        let valuesToActivate = ValuesLibrary.allValues.filter { selectedValues.contains($0.name) }

        // Add them to dataManager with isActive = true
        for value in valuesToActivate {
            var newValue = value
            newValue.isActive = true
            dataManager.values.append(newValue)
        }

        dismiss()
    }
}

struct InitialValueRow: View {
    let valueName: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(valueName)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Permission Manager
class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isAuthorized = false
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        checkAuthorization()
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    private func checkAuthorization() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
}
