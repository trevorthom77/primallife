import SwiftUI

struct UpcomingTripsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var destination = ""
    @State private var arrivalDate = Date()
    @State private var departingDate = Date()
    @State private var showProfilePicture = false
    @FocusState private var isDestinationFocused: Bool
    private let imageNames = ["travel2", "travel3", "travel4"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming trips")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Share the destination and your arrival and departing dates.")
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
                            .frame(height: 110)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    TextField("Where are you going?", text: $destination)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .focused($isDestinationFocused)
                        .padding()
                        .background(Colors.card)
                        .cornerRadius(12)
                        .submitLabel(.done)
                        .onSubmit {
                            isDestinationFocused = false
                        }
                    
                    DatePicker("Arrival date", selection: $arrivalDate, displayedComponents: .date)
                        .font(.travelDetail)
                        .foregroundColor(Colors.primaryText)
                        .padding()
                        .background(Colors.card)
                        .cornerRadius(12)
                    
                    DatePicker("Departing date", selection: $departingDate, displayedComponents: .date)
                        .font(.travelDetail)
                        .foregroundColor(Colors.primaryText)
                        .padding()
                        .background(Colors.card)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 48)
            
            VStack(spacing: 16) {
                Button {
                    showProfilePicture = true
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
        .navigationDestination(isPresented: $showProfilePicture) {
            ProfilePictureView()
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            isDestinationFocused = false
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    UpcomingTripsView()
}
