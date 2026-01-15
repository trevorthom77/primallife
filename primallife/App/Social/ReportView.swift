import SwiftUI
import Supabase

struct ReportView: View {
    let reportedUserID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var selectedOption: String?
    @State private var reportDetails = ""
    @State private var isSubmitting = false
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
    
    private var isSubmitDisabled: Bool {
        selectedOption == nil || reportDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                Button {
                    Task {
                        await submitReport()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Submit")
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)

                        if isSubmitting {
                            ProgressView()
                                .tint(Colors.tertiaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Colors.accent)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .disabled(isSubmitDisabled)
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

    @MainActor
    private func submitReport() async {
        let trimmedDetails = reportDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSubmitting,
              let supabase,
              let reportedUserID,
              let reason = selectedOption,
              !trimmedDetails.isEmpty
        else { return }

        isSubmitting = true

        struct ReportInsert: Encodable {
            let reportedID: UUID
            let reason: String
            let details: String?

            enum CodingKeys: String, CodingKey {
                case reportedID = "reported_id"
                case reason
                case details
            }
        }

        do {
            let payload = ReportInsert(
                reportedID: reportedUserID,
                reason: reason,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails
            )
            try await supabase
                .from("user_reports")
                .insert(payload)
                .execute()
            dismiss()
        } catch {
            isSubmitting = false
            return
        }
    }
}
