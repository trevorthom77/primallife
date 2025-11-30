import SwiftUI

struct MeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: String?
    private let options = ["Only Girls", "Only Boys", "Everyone"]
    private let imageNames = ["profile4", "profile5", "profile6"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    BackButton {
                        dismiss()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Who do you want to travel with?")
                            .font(.onboardingTitle)
                            .foregroundColor(Colors.primaryText)
                        Text("This helps us match you with people you want to travel with.")
                            .font(.travelBody)
                            .foregroundColor(Colors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    ForEach(imageNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selectedOption = option
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.travelBody)
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
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 18)
            
            Button { } label: {
                Text("Continue")
                    .font(.travelDetail)
                    .foregroundColor(Colors.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Colors.accent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    MeetingView()
}
