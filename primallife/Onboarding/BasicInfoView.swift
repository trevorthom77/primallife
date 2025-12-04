import SwiftUI

struct BasicInfoView: View {
    @State private var name = ""
    @State private var birthday = Date()
    @State private var showLanguages = false
    @FocusState private var isNameFieldFocused: Bool
    
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
                        Image("travel1")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Image("travel2")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    VStack(spacing: 12) {
                        Image("travel3")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Image("travel4")
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
                        
                        TextField("", text: $name, prompt: Text("Enter your name").foregroundColor(Colors.secondaryText))
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birthday")
                            .font(.travelDetail)
                            .foregroundColor(Colors.primaryText)
                        
                        DatePicker("", selection: $birthday, displayedComponents: .date)
                            .labelsHidden()
                            .font(.travelBody)
                            .foregroundColor(Colors.primaryText)
                            .tint(Colors.accent)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Colors.card)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
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
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
            .background(Colors.background)
        }
    }
}

#Preview {
    BasicInfoView()
}
