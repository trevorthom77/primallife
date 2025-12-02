import SwiftUI

struct GenderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGender: String?
    private let options = ["Male", "Female", "Other"]
    private let imageNames = ["profile1", "profile2", "profile3"]
    
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
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button { } label: {
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
    }
}

#Preview {
    GenderView()
}
