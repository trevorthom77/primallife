import SwiftUI

struct GenderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGender: String?
    @State private var showMeeting = false
    private let options = ["Male", "Female", "Other"]
    
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
                
                HStack(spacing: 12) {
                    Image("profile1")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Image("profile2")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .frame(maxWidth: .infinity)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                selectedGender = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(selectedGender == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    Spacer()
                                }
                                .foregroundColor(selectedGender == option ? Colors.tertiaryText : Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedGender == option ? Colors.accent : Colors.card)
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
}
