import SwiftUI

struct OriginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var searchText = ""
    @State private var showGender = false
    @FocusState private var isSearchFocused: Bool
    
    private var selectedCountryText: String {
        guard let selectedCountryID = onboardingViewModel.selectedCountryID,
              let country = CountryDatabase.all.first(where: { $0.id == selectedCountryID }) else {
            return ""
        }
        return "\(country.flag) \(country.name)"
    }
    
    private var filteredCountries: [Country] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        
        if query.isEmpty || query == selectedCountryText {
            return CountryDatabase.all
        }
        return CountryDatabase.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    private var isContinueEnabled: Bool {
        onboardingViewModel.selectedCountryID != nil
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Where are you from?")
                        Text("🗺️")
                            .font(.custom(Fonts.semibold, size: 36))
                    }
                    .font(.onboardingTitle)
                    .foregroundColor(Colors.primaryText)
                    Text("This helps us match you with people who share similar origin.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Colors.secondaryText)
                    TextField("Search city or country", text: $searchText)
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
                        ForEach(filteredCountries) { country in
                            let isSelected = onboardingViewModel.selectedCountryID == country.id
                            
                            Button {
                                if isSelected {
                                    onboardingViewModel.selectedCountryID = nil
                                    searchText = ""
                                } else {
                                    onboardingViewModel.selectedCountryID = country.id
                                    searchText = "\(country.flag) \(country.name)"
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(country.flag)
                                        .font(.travelTitle)
                                    Text(country.name)
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
                    showGender = true
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
        .navigationDestination(isPresented: $showGender) {
            GenderView()
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            isSearchFocused = false
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    OriginView()
        .environmentObject(OnboardingViewModel())
}
