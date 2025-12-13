import SwiftUI
import Supabase

private struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient? = nil
}

extension EnvironmentValues {
    var supabaseClient: SupabaseClient? {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}

@main
struct primallifeApp: App {
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://fefucqrztvepcbfjikrq.supabase.co")!,
        supabaseKey: "sb_publishable_2AWQG4a-U37T-pgp5FYnJA_28ymb116"
    )
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var isAuthenticated = false
    @State private var isCheckingSession = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingSession {
                    ZStack {
                        Colors.background
                            .ignoresSafeArea()
                        
                        Text("Live Life")
                            .font(.loadingTitle)
                            .foregroundColor(Colors.primaryText)
                    }
                } else if isAuthenticated && onboardingViewModel.hasCompletedOnboarding {
                    NavigationStack {
                        HomeView()
                    }
                } else {
                    ContentView(supabase: supabase)
                }
            }
            .task {
                await initializeSession()
            }
            .task {
                await observeAuthChanges()
            }
            .environment(\.supabaseClient, supabase)
            .environmentObject(onboardingViewModel)
        }
    }
    
    private func initializeSession() async {
        do {
            _ = try await supabase.auth.session
        } catch {
            await MainActor.run {
                isCheckingSession = false
                isAuthenticated = false
                onboardingViewModel.hasCompletedOnboarding = false
            }
            return
        }
        
        guard let userID = supabase.auth.currentUser?.id else {
            await MainActor.run {
                isCheckingSession = false
                isAuthenticated = false
                onboardingViewModel.hasCompletedOnboarding = false
            }
            return
        }
        
        do {
            let response: [OnboardingCompletion] = try await supabase
                .from("onboarding")
                .select("completed_at")
                .eq("id", value: "\(userID)")
                .limit(1)
                .execute()
                .value
            
            let completedAt = response.first?.completedAt
            await MainActor.run {
                onboardingViewModel.hasCompletedOnboarding = completedAt != nil
                isAuthenticated = true
                isCheckingSession = false
            }
        } catch {
            await MainActor.run {
                onboardingViewModel.hasCompletedOnboarding = false
                isAuthenticated = false
                isCheckingSession = false
            }
            print("Onboarding status fetch failed: \(error)")
        }
    }
    
    private func observeAuthChanges() async {
        for await state in supabase.auth.authStateChanges {
            let hasSession = state.session != nil
            
            await MainActor.run {
                isAuthenticated = hasSession
                if !hasSession {
                    onboardingViewModel.hasCompletedOnboarding = false
                }
            }
        }
    }
    
    private struct OnboardingCompletion: Decodable {
        let completedAt: String?
        
        private enum CodingKeys: String, CodingKey {
            case completedAt = "completed_at"
        }
    }
}
