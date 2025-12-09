import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showUpcomingTrips = false
    @FocusState private var isBioFocused: Bool
    
    private var isContinueEnabled: Bool {
        !onboardingViewModel.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
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
                    Image("travel24")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("travel25")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .topLeading) {
                    if onboardingViewModel.bio.isEmpty {
                        Text("Share what other travelers should know about you")
                            .font(.travelBody)
                            .foregroundColor(Colors.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $onboardingViewModel.bio)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .padding(12)
                        .frame(height: 200)
                        .scrollContentBackground(.hidden)
                        .focused($isBioFocused)
                }
                .background(Colors.card)
                .cornerRadius(12)
                
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
                .disabled(!isContinueEnabled)
                .opacity(isContinueEnabled ? 1 : 0.6)
                
                Button {
                    showUpcomingTrips = true
                } label: {
                    Text("Skip")
                        .font(.travelDetail)
                        .foregroundColor(Colors.primaryText)
                        .frame(maxWidth: .infinity)
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
        .environmentObject(OnboardingViewModel())
}
