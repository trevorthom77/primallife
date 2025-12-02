
import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @State private var showTopLeft = false
    @State private var showTopRight = false
    @State private var showBottomLeft = false
    @State private var showBottomRight = false
    @State private var showMiddle = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Colors.accent.opacity(0.2),
                    Colors.background,
                    Colors.background,
                    Colors.accent.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Image("travel1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(alignment: .topTrailing) {
                            Text("🇪🇸")
                                .font(.travelTitle)
                                .padding(12)
                        }
                        .scaleEffect(showTopLeft ? 1 : 0.01)
                        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showTopLeft)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showTopLeft)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.leading, 24)
                        .padding(.top, -200)
                    
                    Image("travel2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(alignment: .topTrailing) {
                            Text("🇯🇵")
                                .font(.travelTitle)
                                .padding(12)
                        }
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
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(alignment: .topTrailing) {
                            Text("🇮🇹")
                                .font(.travelTitle)
                                .padding(12)
                        }
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
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(alignment: .topTrailing) {
                            Text("🇧🇷")
                                .font(.travelTitle)
                                .padding(12)
                        }
                        .scaleEffect(showBottomLeft ? 1 : 0.01)
                        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showBottomLeft)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showBottomLeft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 340)
                        .padding(.leading, 12)
                    
                    Image("travel5")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay(alignment: .topTrailing) {
                            Text("🇺🇸")
                                .font(.travelTitle)
                                .padding(12)
                        }
                        .rotationEffect(.degrees(16))
                        .scaleEffect(showBottomRight ? 1 : 0.01)
                        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: showBottomRight)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showBottomRight)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 360)
                        .padding(.trailing, 36)
                }
                
                Spacer()
            }
            
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("You only live once")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    
                    SignInWithAppleButton(.signIn) { _ in
                    } onCompletion: { _ in
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .signInWithAppleButtonStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            startPopSequence()
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
}

#Preview {
    ContentView()
}
