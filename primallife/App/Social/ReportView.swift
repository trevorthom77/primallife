import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: String?
    @State private var reportDetails = ""
    @FocusState private var isDetailsFocused: Bool
    
    private let reportOptions = [
        "Harassment or bullying",
        "Sexual harassment",
        "Safety concern",
        "Scam or fraud",
        "Inappropriate content",
        "Fake profile",
        "Spam",
        "Other"
    ]

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Report")
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)

                        Text("Select a reason and share details so we can review.")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 10) {
                        ForEach(reportOptions, id: \.self) { option in
                            let isSelected = selectedOption == option
                            
                            Button {
                                selectedOption = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(.travelDetail)
                                    
                                    Spacer()
                                }
                                .foregroundStyle(isSelected ? Colors.tertiaryText : Colors.primaryText)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .frame(maxWidth: .infinity)
                                .background(isSelected ? Colors.accent : Colors.card)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.travelTitle)
                            .foregroundStyle(Colors.primaryText)

                        Text("Be clear and specific so we can review quickly.")
                            .font(.travelBody)
                            .foregroundStyle(Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        TextEditor(text: $reportDetails)
                            .font(.travelBody)
                            .foregroundStyle(Colors.primaryText)
                            .padding(12)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .background(Colors.card)
                            .cornerRadius(12)
                            .focused($isDetailsFocused)
                    }

                }
                .padding(.horizontal, 20)
                .padding(.top, 72)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
            .contentShape(Rectangle())
            .onTapGesture {
                isDetailsFocused = false
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {}) {
                    Text("Submit")
                        .font(.travelDetail)
                        .foregroundStyle(Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.accent)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .background(Colors.background)
        }
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .topLeading) {
            BackButton {
                dismiss()
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
    }
}
