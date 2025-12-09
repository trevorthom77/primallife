import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showWelcomeProfile = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enable notifications")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Get notified when other travelers message you.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                VStack(spacing: 12) {
                    infoCard(
                        emoji: "💬",
                        title: "Never miss a traveler message"
                    )
                    
                    HStack(spacing: 12) {
                        Text("🗓️")
                            .font(.onboardingTitle)
                            .foregroundColor(Colors.primaryText)
                        
                        Text("Always be updated on the plans")
                            .font(.travelBody)
                            .foregroundColor(Colors.primaryText)
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Colors.card)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showWelcomeProfile = true
                } label: {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.goBackFont)
                        .foregroundColor(Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .navigationDestination(isPresented: $showWelcomeProfile) {
            WelcomeProfileView()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    private func infoCard(emoji: String, title: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.onboardingTitle)
                .foregroundColor(Colors.primaryText)
            
            Text(title)
                .font(.travelBody)
                .foregroundColor(Colors.primaryText)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Colors.card)
        .cornerRadius(12)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
}

#Preview {
    NotificationsView()
}
