import SwiftUI

struct MeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: String?
    @State private var showInterests = false
    private let options = ["Only Girls", "Only Boys", "Everyone"]
    
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
                
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(["profile4", "profile5", "profile6", "profile7"], id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                selectedOption = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(selectedOption == option ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    Spacer()
                                }
                                .foregroundColor(selectedOption == option ? Colors.tertiaryText : Colors.primaryText)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedOption == option ? Colors.accent : Colors.card)
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
}
