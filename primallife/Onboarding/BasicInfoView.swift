import SwiftUI

struct BasicInfoView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var showLanguages = false
    @State private var showBirthdayPicker = false
    @State private var showBirthdayWarning = false
    @FocusState private var isNameFieldFocused: Bool
    
    private var birthdayText: String {
        onboardingViewModel.birthday.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var maximumBirthday: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    private var birthdayBinding: Binding<Date> {
        Binding(
            get: { onboardingViewModel.birthday },
            set: { newValue in
                let clamped = min(newValue, maximumBirthday)
                showBirthdayWarning = newValue > maximumBirthday
                onboardingViewModel.birthday = clamped
                onboardingViewModel.hasSelectedBirthday = true
            }
        )
    }
    
    private var isContinueEnabled: Bool {
        !onboardingViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && onboardingViewModel.hasSelectedBirthday
            && onboardingViewModel.hasAcceptedTerms
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Basic info")
                        .font(.onboardingTitle)
                        .foregroundColor(Colors.primaryText)
                    Text("Start your profile with the essentials.")
                        .font(.travelBody)
                        .foregroundColor(Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    VStack(spacing: 12) {
                        Image("travel6")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Image("travel7")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    VStack(spacing: 12) {
                        Image("travel8")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Image("travel9")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.travelDetail)
                            .foregroundColor(Colors.primaryText)
                        
                        TextField("", text: $onboardingViewModel.name, prompt: Text("Enter your name").foregroundColor(Colors.secondaryText))
                            .font(.travelBody)
                            .foregroundColor(Colors.primaryText)
                            .focused($isNameFieldFocused)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit {
                                isNameFieldFocused = false
                            }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Colors.card)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isNameFieldFocused = true
                    }
                    
                    Button {
                        showBirthdayPicker = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Birthday")
                                .font(.travelDetail)
                                .foregroundColor(Colors.primaryText)
                            
                            HStack {
                                Text(onboardingViewModel.hasSelectedBirthday ? birthdayText : "Select your birthday")
                                    .font(.travelBody)
                                    .foregroundColor(onboardingViewModel.hasSelectedBirthday ? Colors.primaryText : Colors.secondaryText)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.card)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
        }
        .onAppear {
            if onboardingViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onboardingViewModel.name = "Traveler"
            }
        }
        .onTapGesture {
            isNameFieldFocused = false
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showLanguages) {
            LanguagesView()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Button {
                        onboardingViewModel.hasAcceptedTerms.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: onboardingViewModel.hasAcceptedTerms ? "checkmark.square.fill" : "square")
                                .font(.travelDetail)
                                .foregroundColor(onboardingViewModel.hasAcceptedTerms ? Colors.accent : Colors.secondaryText)
                            
                            Text("Agree to")
                                .font(.travelDetail)
                                .foregroundColor(Colors.primaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Link("terms", destination: URL(string: "https://polyester-tire-f2c.notion.site/2e942fcc204a807c91c9e93983b616c1?pvs=74")!)
                        .font(.travelDetail)
                        .foregroundColor(Colors.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Colors.card)
                .cornerRadius(12)
                
                Button {
                    showLanguages = true
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
            .background(Colors.background)
        }
        .sheet(isPresented: $showBirthdayPicker) {
            ZStack {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        
                        Button("Done") {
                            showBirthdayPicker = false
                        }
                        .font(.travelDetail)
                        .foregroundColor(Colors.accent)
                    }
                    
                    DatePicker("", selection: birthdayBinding, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(Colors.accent)
                    
                    if showBirthdayWarning {
                        Text("You must be 18 or older.")
                            .font(.travelDetail)
                            .foregroundColor(Colors.accent)
                    }
                }
                .padding(20)
            }
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .preferredColorScheme(.light)
        }
    }
}

#Preview {
    BasicInfoView()
        .environmentObject(OnboardingViewModel())
}
