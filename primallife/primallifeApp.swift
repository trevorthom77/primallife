import SwiftUI
import Supabase
import Combine

private struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient? = nil
}

extension EnvironmentValues {
    var supabaseClient: SupabaseClient? {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}

@MainActor
final class ProfileStore: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cachedAvatarImage: Image?
    @Published var cachedAvatarURL: URL?
    @Published var cachedFriends: [UserProfile] = []
    @Published var hasLoadedFriends = false
    @Published var cachedFriendImages: [URL: Image] = [:]
    
    func loadProfile(for userID: UUID, supabase: SupabaseClient?) async {
        guard let supabase else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value
            
            profile = profiles.first
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func clear() {
        profile = nil
        isLoading = false
        errorMessage = nil
        cachedAvatarImage = nil
        cachedAvatarURL = nil
        cachedFriends = []
        hasLoadedFriends = false
        cachedFriendImages = [:]
    }

    func cacheAvatar(_ image: Image, url: URL) {
        cachedAvatarImage = image
        cachedAvatarURL = url
    }

    func cacheFriendImage(_ image: Image, url: URL) {
        cachedFriendImages[url] = image
    }
}

@main
struct primallifeApp: App {
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://fefucqrztvepcbfjikrq.supabase.co")!,
        supabaseKey: "sb_publishable_2AWQG4a-U37T-pgp5FYnJA_28ymb116"
    )
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var profileStore = ProfileStore()
    @State private var isAuthenticated = false
    @State private var isCheckingSession = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingSession {
                    ZStack {
                        Colors.background
                            .ignoresSafeArea()
                        
                        HStack(spacing: 12) {
                            Image("logo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            
                            Text("Live Life")
                                .font(.loadingTitle)
                                .foregroundColor(Colors.primaryText)
                        }
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
            .environmentObject(profileStore)
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
                profileStore.clear()
            }
            return
        }
        
        guard let userID = supabase.auth.currentUser?.id else {
            await MainActor.run {
                isCheckingSession = false
                isAuthenticated = false
                onboardingViewModel.hasCompletedOnboarding = false
                profileStore.clear()
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
            
            await profileStore.loadProfile(for: userID, supabase: supabase)
            
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
                profileStore.clear()
            }
            print("Onboarding status fetch failed: \(error)")
        }
    }
    
    private func observeAuthChanges() async {
        for await state in supabase.auth.authStateChanges {
            let hasSession = state.session != nil
            let userID = state.session?.user.id
            
            await MainActor.run {
                isAuthenticated = hasSession
                if !hasSession {
                    onboardingViewModel.hasCompletedOnboarding = false
                    profileStore.clear()
                }
            }
            
            if let userID, hasSession {
                await profileStore.loadProfile(for: userID, supabase: supabase)
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
