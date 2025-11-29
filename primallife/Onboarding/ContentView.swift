
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
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Image("travel1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color(hex: "#06d6a0"), lineWidth: 4)
                        }
                        .scaleEffect(showTopLeft ? 1 : 0.6)
                        .opacity(showTopLeft ? 1 : 0)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showTopLeft)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.leading, 24)
                        .padding(.top, -200)
                    
                    Image("travel2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color(hex: "#40e0d0"), lineWidth: 4)
                        }
                        .rotationEffect(.degrees(10))
                        .scaleEffect(showTopRight ? 1 : 0.6)
                        .opacity(showTopRight ? 1 : 0)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showTopRight)
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                        .padding(.top, -184)
                        .padding(.trailing, 24)
                    
                    Image("travel3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Colors.card, lineWidth: 4)
                        }
                        .rotationEffect(.degrees(-8))
                        .zIndex(1)
                        .scaleEffect(showMiddle ? 1 : 0.6)
                        .opacity(showMiddle ? 1 : 0)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showMiddle)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.top, 0)
                    
                    Image("travel4")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Colors.accent, lineWidth: 4)
                        }
                        .scaleEffect(showBottomLeft ? 1 : 0.6)
                        .opacity(showBottomLeft ? 1 : 0)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showBottomLeft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 340)
                        .padding(.leading, 12)
                    
                    Image("travel5")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color(hex: "#1ca9c9"), lineWidth: 4)
                        }
                        .rotationEffect(.degrees(16))
                        .scaleEffect(showBottomRight ? 1 : 0.6)
                        .opacity(showBottomRight ? 1 : 0)
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
                        .padding(.bottom, 8)
                    
                    SignInWithAppleButton(.signIn) { _ in
                    } onCompletion: { _ in
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .signInWithAppleButtonStyle(.black)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showTopLeft = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStep) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showTopRight = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStep * 2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showBottomLeft = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStep * 3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showBottomRight = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delayStep * 4) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showMiddle = true
            }
        }
    }
}

#Preview {
    ContentView()
}
