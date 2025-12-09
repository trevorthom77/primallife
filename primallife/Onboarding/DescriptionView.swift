import SwiftUI

struct DescriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showAbout = false
    private let options = [
        "Backpacking",
        "Gap year",
        "Studying abroad",
        "Living abroad",
        "Just love to travel",
        "Digital nomad"
    ]
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.travelDescription != nil
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What describes you best?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Pick the travel situation that fits right now.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Image("travel21")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 96)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("travel22")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 96)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("travel23")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 96)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                onboardingViewModel.travelDescription = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(onboardingViewModel.travelDescription == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    Spacer()
                                }
                                .foregroundColor(onboardingViewModel.travelDescription == option ? Colors.tertiaryText : Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(onboardingViewModel.travelDescription == option ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button {
                    showAbout = true
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
            .background(Colors.background)
        }
        .navigationDestination(isPresented: $showAbout) {
            AboutView()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    DescriptionView()
        .environmentObject(OnboardingViewModel())
}
