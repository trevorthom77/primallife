import SwiftUI

struct InterestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedInterests: Set<String> = []
    @State private var showMeetingUp = false
    private let interests = [
        "🧭 Adventure",
        "✝️ God",
        "🧳 Solo Traveling",
        "🚗 Road Trips",
        "🚐 Van Travel",
        "🛳️ Cruises",
        "🛥️ Boats",
        "⛵️ Sailing",
        "🚤 Jet Skis",
        "🏝️ Island Hopping",
        "🤿 Scuba Diving",
        "🏄 Surfing",
        "🛶 Kayaking",
        "🎣 Fishing",
        "🦈 Sharks",
        "🌊 Ocean",
        "🏖️ Beaches",
        "🌴 Tropical",
        "🌧️ Rainforests",
        "🍃 Nature",
        "🏞️ National Parks",
        "🧗 Rock Climbing",
        "🥾 Hiking",
        "🚲 Biking",
        "⛺️ Camping",
        "🌲 Off Grid",
        "🎿 Snow and Ski",
        "🏅 Sports",
        "🐶 Animal Lover",
        "🍽️ Food",
        "🛍️ Shopping",
        "🍻 Bar Hopping",
        "🌃 Nightlife",
        "🎨 Art",
        "📸 Photography",
        "🖼️ Museums",
        "🛏️ Hostels",
        "💸 Budget Travel",
        "🛎️ Luxury Travel"
    ]
    
    private var isContinueEnabled: Bool {
        !selectedInterests.isEmpty
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What are your interests?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("This helps us match you with people who share your interests.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(interests, id: \.self) { interest in
                            let isSelected = selectedInterests.contains(interest)
                            
                            Button {
                                toggleSelection(for: interest)
                            } label: {
                                Text(interest)
                                    .font(isSelected ? .custom(Fonts.semibold, size: 20) : .travelBody)
                                    .foregroundColor(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Colors.accent : Colors.card)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button {
                    showMeetingUp = true
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
            .background(Colors.background)
        }
        .navigationDestination(isPresented: $showMeetingUp) {
            MeetingUpView()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func toggleSelection(for interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else if selectedInterests.count < 6 {
            selectedInterests.insert(interest)
        }
    }
}

#Preview {
    InterestView()
}
