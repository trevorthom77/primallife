import SwiftUI

struct GenderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showMeeting = false
    private let options = ["Male", "Female", "Other"]
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.selectedGender != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What is your gender?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Choose the option that fits you best.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                GeometryReader { geometry in
                    let width = min((geometry.size.width - 24) / 3, 140)
                    
                    HStack(spacing: 12) {
                        ForEach(["travel26", "travel27", "travel28"], id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 110)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                onboardingViewModel.selectedGender = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(onboardingViewModel.selectedGender == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    Spacer()
                                }
                                .foregroundColor(onboardingViewModel.selectedGender == option ? Colors.tertiaryText : Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(onboardingViewModel.selectedGender == option ? Colors.accent : Colors.card)
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
                    showMeeting = true
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
        .navigationDestination(isPresented: $showMeeting) {
            MeetingView()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    GenderView()
        .environmentObject(OnboardingViewModel())
}
