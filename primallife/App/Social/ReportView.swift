import SwiftUI
import Supabase

struct ReportView: View {
    let reportedUserID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var selectedOption: String?
    @State private var reportDetails = ""
    @State private var isSubmitting = false
    @State private var isShowingBlockPrompt = false
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

    private struct BlockStatusRow: Decodable {
        let blockerID: UUID

        enum CodingKeys: String, CodingKey {
            case blockerID = "blocker_id"
        }
    }
    
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
                    guard !isSubmitting else { return }
                    Task {
                        await handleSubmitTap()
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
        .overlay {
            if isShowingBlockPrompt {
                confirmationOverlay(
                    title: "Block this user?",
                    message: "Do you want to block this user as well?",
                    secondaryTitle: "Report Only",
                    primaryTitle: "Report & Block",
                    isDestructive: true,
                    primaryAction: {
                        isShowingBlockPrompt = false
                        Task {
                            await submitReport(shouldBlock: true)
                        }
                    },
                    secondaryAction: {
                        isShowingBlockPrompt = false
                        Task {
                            await submitReport(shouldBlock: false)
                        }
                    }
                )
            }
        }
    }

    @MainActor
    private func handleSubmitTap() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id,
              let reportedUserID
        else {
            isShowingBlockPrompt = true
            return
        }

        do {
            let rows: [BlockStatusRow] = try await supabase
                .from("blocks")
                .select("blocker_id")
                .eq("blocker_id", value: currentUserID.uuidString)
                .eq("blocked_id", value: reportedUserID.uuidString)
                .limit(1)
                .execute()
                .value

            if rows.isEmpty {
                isShowingBlockPrompt = true
            } else {
                await submitReport(shouldBlock: false)
            }
        } catch {
            isShowingBlockPrompt = true
        }
    }

    @MainActor
    private func submitReport(shouldBlock: Bool) async {
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
            if shouldBlock {
                await blockUser(reportedUserID: reportedUserID)
            }
            dismiss()
        } catch {
            isSubmitting = false
            return
        }
    }

    private func blockUser(reportedUserID: UUID) async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id,
              currentUserID != reportedUserID
        else { return }

        struct BlockInsert: Encodable {
            let blockerID: UUID
            let blockedID: UUID

            enum CodingKeys: String, CodingKey {
                case blockerID = "blocker_id"
                case blockedID = "blocked_id"
            }
        }

        do {
            try await supabase
                .from("blocks")
                .insert(
                    BlockInsert(
                        blockerID: currentUserID,
                        blockedID: reportedUserID
                    )
                )
                .execute()

            _ = try? await supabase
                .from("friend_requests")
                .delete()
                .eq("requester_id", value: currentUserID.uuidString)
                .eq("receiver_id", value: reportedUserID.uuidString)
                .execute()

            _ = try? await supabase
                .from("friend_requests")
                .delete()
                .eq("requester_id", value: reportedUserID.uuidString)
                .eq("receiver_id", value: currentUserID.uuidString)
                .execute()

            _ = try? await supabase
                .from("friends")
                .delete()
                .eq("user_id", value: currentUserID.uuidString)
                .eq("friend_id", value: reportedUserID.uuidString)
                .execute()

            _ = try? await supabase
                .from("friends")
                .delete()
                .eq("user_id", value: reportedUserID.uuidString)
                .eq("friend_id", value: currentUserID.uuidString)
                .execute()
        } catch {
            return
        }
    }

    private func confirmationOverlay(
        title: String,
        message: String,
        secondaryTitle: String,
        primaryTitle: String,
        isDestructive: Bool,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        ZStack {
            Colors.primaryText
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(title)
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                Text(message)
                    .font(.travelBody)
                    .foregroundStyle(Colors.secondaryText)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: primaryAction) {
                        Text(primaryTitle)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isDestructive ? Color.red : Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(action: secondaryAction) {
                        Text(secondaryTitle)
                            .font(.travelDetail)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Colors.secondaryText.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
}
