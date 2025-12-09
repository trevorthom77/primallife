import SwiftUI

struct MeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showInterests = false
    private let options = ["Only Girls", "Only Boys", "Everyone"]
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.travelCompanionPreference != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Who do you want to travel with?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("This helps us match you with people you want to travel with.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    ForEach(["travel12", "travel13", "travel14"], id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 110)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                onboardingViewModel.travelCompanionPreference = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(onboardingViewModel.travelCompanionPreference == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    Spacer()
                                }
                                .foregroundColor(onboardingViewModel.travelCompanionPreference == option ? Colors.tertiaryText : Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(onboardingViewModel.travelCompanionPreference == option ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 200)
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showInterests = true
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
        }
        .navigationDestination(isPresented: $showInterests) {
            InterestView()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MeetingView()
        .environmentObject(OnboardingViewModel())
}
