import SwiftUI

struct LanguagesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredLanguages: [Language] {
        if searchText.isEmpty {
            return LanguageDatabase.all
        }
        return LanguageDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What languages do you speak?")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("This helps us match you with people with similar languages.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    ForEach(["profile7", "profile8", "profile9"], id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField("Search languages", text: $searchText)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .cornerRadius(12)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredLanguages) { language in
                            HStack(spacing: 12) {
                                Text(language.flag)
                                    .font(.travelTitle)
                                Text(language.name)
                                    .font(.travelBody)
                                    .foregroundColor(Colors.primaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Colors.card)
                            .cornerRadius(12)
                        }
                    }
                }
                .frame(maxHeight: 260)
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
        }
        .safeAreaInset(edge: .bottom) {
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
            .background(Colors.background)
        }
    }
}

#Preview {
    LanguagesView()
}
