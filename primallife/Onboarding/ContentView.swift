
import SwiftUI
import AuthenticationServices
import Supabase
import CryptoKit

struct ContentView: View {
    let supabase: SupabaseClient
    
    @State private var showTopLeft = false
    @State private var showTopRight = false
    @State private var showBottomLeft = false
    @State private var showBottomRight = false
    @State private var showMiddle = false
    @State private var showBasicInfo = false
    @State private var showHome = false
    @State private var currentNonce: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.contentview
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ZStack {
                        Image("travel1")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .scaleEffect(showTopLeft ? 1 : 0.01)
                            .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showTopLeft)
                            .sensoryFeedback(.impact(weight: .medium), trigger: showTopLeft)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.leading, 24)
                            .padding(.top, -160)
                        
                        Image("travel2")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .rotationEffect(.degrees(10))
                            .scaleEffect(showTopRight ? 1 : 0.01)
                            .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showTopRight)
                            .sensoryFeedback(.impact(weight: .medium), trigger: showTopRight)
                            .frame(maxWidth: .infinity, alignment: .topTrailing)
                            .padding(.top, -184)
                            .padding(.trailing, 24)
                        
                        Image("travel3")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .rotationEffect(.degrees(-8))
                            .zIndex(1)
                            .scaleEffect(showMiddle ? 1 : 0.01)
                            .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showMiddle)
                            .sensoryFeedback(.impact(weight: .medium), trigger: showMiddle)
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(.top, 0)
                        
                        Image("travel4")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .rotationEffect(.degrees(-4))
                            .scaleEffect(showBottomLeft ? 1 : 0.01)
                            .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showBottomLeft)
                            .sensoryFeedback(.impact(weight: .medium), trigger: showBottomLeft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 300)
                            .padding(.leading, 20)
                        
                        Image("travel5")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .rotationEffect(.degrees(10))
                            .scaleEffect(showBottomRight ? 1 : 0.01)
                            .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showBottomRight)
                            .sensoryFeedback(.impact(weight: .medium), trigger: showBottomRight)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 340)
                            .padding(.trailing, 36)
                    }
                    
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("U only live once")
                            .font(.onboardingTitle)
                            .foregroundColor(Colors.primaryText)
                        
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonce()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            if case .success(let auth) = result,
                           let appleID = auth.credential as? ASAuthorizationAppleIDCredential,
                           let tokenData = appleID.identityToken,
                           let token = String(data: tokenData, encoding: .utf8),
                           let nonce = currentNonce {
                                Task {
                                    do {
                                        try await supabase.auth.signInWithIdToken(
                                            credentials: .init(
                                                provider: .apple,
                                                idToken: token,
                                                nonce: nonce
                                            )
                                        )
                                        await checkOnboardingCompletion()
                                    } catch {
                                        print("Apple sign-in failed: \(error)")
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .cornerRadius(16)
                        .signInWithAppleButtonStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 64)
                }
            }
            .onAppear {
                startPopSequence()
            }
            .navigationDestination(isPresented: $showBasicInfo) {
                BasicInfoView()
            }
            .navigationDestination(isPresented: $showHome) {
                HomeView()
            }
        }
    }
    
    private func startPopSequence() {
        let delayStep: TimeInterval = 0.25
        let initialDelay: TimeInterval = 0.3
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            showTopLeft = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + delayStep) {
            showTopRight = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + delayStep * 2) {
            showBottomLeft = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + delayStep * 3) {
            showBottomRight = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + delayStep * 4) {
            showMiddle = true
        }
    }
    
    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let random = charset.randomElement() {
                result.append(random)
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
    
    private struct OnboardingCompletion: Decodable {
        let completedAt: String?
        
        private enum CodingKeys: String, CodingKey {
            case completedAt = "completed_at"
        }
    }
    
    private func checkOnboardingCompletion() async {
        guard let userID = supabase.auth.currentUser?.id else { return }
        
        do {
            let response: [OnboardingCompletion] = try await supabase
                .from("onboarding")
                .select("completed_at")
                .eq("user_id", value: "\(userID)")
                .limit(1)
                .execute()
                .value
            
            let completedAt = response.first?.completedAt
            await MainActor.run {
                showHome = completedAt != nil
                showBasicInfo = completedAt == nil
            }
        } catch {
            await MainActor.run {
                showBasicInfo = true
            }
            print("Onboarding completion check failed: \(error)")
        }
    }
}

#Preview {
    ContentView(
        supabase: SupabaseClient(
            supabaseURL: URL(string: "https://fefucqrztvepcbfjikrq.supabase.co")!,
            supabaseKey: "sb_publishable_2AWQG4a-U37T-pgp5FYnJA_28ymb116"
        )
    )
}
