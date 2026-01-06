import SwiftUI
import Supabase

private struct FriendRequestRow: Decodable {
    let requesterID: UUID
    let receiverID: UUID

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
        case receiverID = "receiver_id"
    }
}

private struct FriendRequestItem: Identifiable {
    let requesterID: UUID
    let receiverID: UUID
    let profile: UserProfile?

    var id: UUID { requesterID }
}

struct BellView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supabaseClient) private var supabase
    @State private var requests: [FriendRequestItem] = []

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton {
                        dismiss()
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(requests) { request in
                            requestCard(request)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await loadRequests()
        }
    }

    private func requestCard(_ request: FriendRequestItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            avatarView(for: request.profile)
                .frame(width: 56, height: 56)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(request.profile?.fullName ?? "")
                    .font(.travelDetail)
                    .foregroundStyle(Colors.primaryText)

                if let origin = originDisplay(for: request.profile) {
                    Text(origin)
                        .font(.badgeDetail)
                        .foregroundStyle(Colors.secondaryText)
                }

                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await acceptRequest(request)
                        }
                    }) {
                        Text("Accept")
                            .font(.tripsfont)
                            .foregroundStyle(Colors.tertiaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            await declineRequest(request)
                        }
                    }) {
                        Text("Decline")
                            .font(.tripsfont)
                            .foregroundStyle(Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Colors.secondaryText.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func avatarView(for profile: UserProfile?) -> some View {
        if let avatarURL = profile?.avatarURL(using: supabase) {
            AsyncImage(url: avatarURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Colors.secondaryText.opacity(0.3)
                }
            }
        } else {
            Colors.secondaryText.opacity(0.3)
        }
    }

    private func originDisplay(for profile: UserProfile?) -> String? {
        guard
            let profile,
            let flag = profile.originFlag,
            let name = profile.originName
        else {
            return nil
        }

        return "\(flag) \(name)"
    }

    private func loadRequests() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else {
            return
        }

        do {
            let rows: [FriendRequestRow] = try await supabase
                .from("friend_requests")
                .select("requester_id, receiver_id")
                .eq("receiver_id", value: currentUserID.uuidString)
                .execute()
                .value

            if rows.isEmpty {
                await MainActor.run {
                    requests = []
                }
                return
            }

            let requesterIDs = rows.map { $0.requesterID.uuidString }
            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .in("id", values: requesterIDs)
                .execute()
                .value

            let profilesByID = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            let items = rows.map { row in
                FriendRequestItem(
                    requesterID: row.requesterID,
                    receiverID: row.receiverID,
                    profile: profilesByID[row.requesterID]
                )
            }

            await MainActor.run {
                requests = items
            }
        } catch {
            return
        }
    }

    private func acceptRequest(_ request: FriendRequestItem) async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else {
            return
        }

        struct FriendInsert: Encodable {
            let userID: UUID
            let friendID: UUID

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case friendID = "friend_id"
            }
        }

        do {
            try await supabase
                .from("friends")
                .insert([
                    FriendInsert(userID: currentUserID, friendID: request.requesterID),
                    FriendInsert(userID: request.requesterID, friendID: currentUserID)
                ])
                .execute()

            try await supabase
                .from("friend_requests")
                .delete()
                .eq("requester_id", value: request.requesterID.uuidString)
                .eq("receiver_id", value: currentUserID.uuidString)
                .execute()

            await MainActor.run {
                requests.removeAll { $0.requesterID == request.requesterID }
            }
        } catch {
            return
        }
    }

    private func declineRequest(_ request: FriendRequestItem) async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else {
            return
        }

        do {
            try await supabase
                .from("friend_requests")
                .delete()
                .eq("requester_id", value: request.requesterID.uuidString)
                .eq("receiver_id", value: currentUserID.uuidString)
                .execute()

            await MainActor.run {
                requests.removeAll { $0.requesterID == request.requesterID }
            }
        } catch {
            return
        }
    }
}

#Preview {
    BellView()
}
