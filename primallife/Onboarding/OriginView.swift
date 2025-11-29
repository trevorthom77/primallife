import SwiftUI

struct OriginView: View {
    @State private var origin = ""
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Where are you from?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    
                    TextField("City, Country", text: $origin)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .padding()
                        .background(Colors.card)
                        .cornerRadius(12)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Colors.card)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32
                    )
                )
            }
        }
    }
}

#Preview {
    OriginView()
}
