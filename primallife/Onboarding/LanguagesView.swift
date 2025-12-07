import SwiftUI

struct LanguagesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showOrigin = false
    @State private var selectedLanguageIDs: Set<String> = []
    @FocusState private var isSearchFocused: Bool
    
    private var filteredLanguages: [Language] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        
        if query.isEmpty {
            return LanguageDatabase.all
        }
        
        return LanguageDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    private var isContinueEnabled: Bool {
        !selectedLanguageIDs.isEmpty
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("What languages do you speak?")
                        Text("🌐")
                            .font(.custom(Fonts.semibold, size: 36))
                    }
                    .font(.onboardingTitle)
                    .foregroundColor(Colors.primaryText)
                    Text("This helps us match you with people with similar languages.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField("Search languages", text: $searchText)
                        .font(.travelBody)
                        .foregroundColor(Colors.primaryText)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            isSearchFocused = false
                        }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Colors.card)
                .cornerRadius(12)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredLanguages) { language in
                            let isSelected = selectedLanguageIDs.contains(language.id)
                            
                            Button {
                                if isSelected {
                                    selectedLanguageIDs.remove(language.id)
                                } else {
                                    selectedLanguageIDs.insert(language.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(language.flag)
                                        .font(.travelTitle)
                                    Text(language.name)
                                        .font(.travelBody)
                                        .foregroundColor(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                    showOrigin = true
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
        .navigationDestination(isPresented: $showOrigin) {
            OriginView()
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            isSearchFocused = false
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    LanguagesView()
}
