import SwiftUI

struct MeetingUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showSplitExpenses = false
    private let options = ["Travel together", "Meet at destination", "Open to both"]
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.meetingStyle != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How do u want to travel with other travelers?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Share how you prefer linking with other travelers.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Image("travel16")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("travel17")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("travel18")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            onboardingViewModel.meetingStyle = option
                        } label: {
                            HStack {
                                Text(option)
                                    .font(onboardingViewModel.meetingStyle == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                Spacer()
                            }
                            .foregroundColor(onboardingViewModel.meetingStyle == option ? Colors.tertiaryText : Colors.primaryText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(onboardingViewModel.meetingStyle == option ? Colors.accent : Colors.card)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showSplitExpenses = true
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
        .navigationDestination(isPresented: $showSplitExpenses) {
            SplitExpensesView()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MeetingUpView()
        .environmentObject(OnboardingViewModel())
}
