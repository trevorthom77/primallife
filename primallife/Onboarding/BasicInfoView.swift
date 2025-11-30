import SwiftUI

struct BasicInfoView: View {
    @State private var name = ""
    @State private var birthday = Date()
    private let imageNames = ["travel1", "travel2", "travel3", "travel4"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Basic info")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("The first steps of your profile.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(imageNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                
                TextField("Name", text: $name)
                    .font(.travelBody)
                    .foregroundColor(Colors.primaryText)
                    .padding()
                    .background(Colors.card)
                    .cornerRadius(12)
                
                DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    .font(.travelDetail)
                    .foregroundColor(Colors.primaryText)
                    .padding()
                    .background(Colors.card)
                    .cornerRadius(12)
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack {
                Button { } label: {
                    Text("Continue")
                        .font(.travelDetail)
                        .foregroundColor(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    BasicInfoView()
}
