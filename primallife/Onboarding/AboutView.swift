import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bio = ""
    @State private var showUpcomingTrips = false
    @FocusState private var isBioFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About you")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Share a short bio so people know you better.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Image("travel1")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("travel2")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $bio)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .frame(height: 200)
                        .padding(12)
                        .background(Colors.card)
                        .cornerRadius(12)
                        .scrollContentBackground(.hidden)
                        .focused($isBioFocused)
                    
                    if bio.isEmpty {
                        Text("Share what other travelers should know about you")
                            .font(.travelBody)
                            .foregroundColor(Colors.secondaryText)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showUpcomingTrips = true
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
        .navigationDestination(isPresented: $showUpcomingTrips) {
            UpcomingTripsView()
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            isBioFocused = false
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    AboutView()
}
