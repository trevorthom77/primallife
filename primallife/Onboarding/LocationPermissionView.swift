import SwiftUI

struct LocationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Turn on your location")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Find travelers near you.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                VStack(spacing: 12) {
                    benefitCard(emoji: "🗺️", title: "Find travelers near you")
                    benefitCard(emoji: "🤝", title: "See travelers going on the same trips")
                    benefitCard(emoji: "🌐", title: "Discover local tribes")
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button { } label: {
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
    }
    
    private func benefitCard(emoji: String, title: String) -> some View {
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
}

#Preview {
    LocationPermissionView()
}
