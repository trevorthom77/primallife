import SwiftUI

struct SplitExpensesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showDescription = false
    private let options = [
        "Yes, let's split the costs",
        "Depends on the trip",
        "Prefer to keep expenses separate"
    ]
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.splitExpensesPreference != nil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Are you open to splitting costs?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Let others know if you'd divide expenses on a trip.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    ForEach(["travel11", "travel10", "travel31"], id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 110)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            onboardingViewModel.splitExpensesPreference = option
                        } label: {
                            HStack {
                                Text(option)
                                    .font(onboardingViewModel.splitExpensesPreference == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .foregroundColor(onboardingViewModel.splitExpensesPreference == option ? Colors.tertiaryText : Colors.primaryText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(onboardingViewModel.splitExpensesPreference == option ? Colors.accent : Colors.card)
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
                    showDescription = true
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
        .navigationDestination(isPresented: $showDescription) {
            DescriptionView()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SplitExpensesView()
        .environmentObject(OnboardingViewModel())
}
