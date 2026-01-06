import SwiftUI
import Supabase

private struct FriendRequestRow: Decodable {
    let requesterID: UUID
    let receiverID: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
        case receiverID = "receiver_id"
        case status
    }
}

private enum FriendRequestKind: String {
    case incoming
    case statusUpdate
}

private struct FriendRequestItem: Identifiable {
    let requesterID: UUID
    let receiverID: UUID
    let status: String
    let kind: FriendRequestKind
    let profile: UserProfile?

    var id: String {
        "\(kind.rawValue)-\(requesterID.uuidString)-\(receiverID.uuidString)"
    }
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
                    if requests.isEmpty {
                        VStack(spacing: 12) {
                            Text("No notifications yet")
                                .font(.travelBody)
                                .foregroundStyle(Colors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(requests) { request in
                                requestCard(request)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
                .padding(.horizontal, 24)
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await loadRequests()
        }
    }

    @ViewBuilder
    private func requestCard(_ request: FriendRequestItem) -> some View {
        if request.kind == .incoming {
            NavigationLink {
                OthersProfileView(userID: request.requesterID)
            } label: {
                requestCardContent(request)
            }
            .buttonStyle(.plain)
        } else {
            requestCardContent(request)
        }
    }

    private func requestCardContent(_ request: FriendRequestItem) -> some View {
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

                if request.kind == .incoming {
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
                        .buttonStyle(.borderless)

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
                        .buttonStyle(.borderless)
                    }
                } else {
                    Text(statusMessage(for: request.status))
                        .font(.tripsfont)
                        .foregroundStyle(Colors.primaryText)
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

    private func statusMessage(for status: String) -> String {
        switch status {
        case "accepted":
            return "Accepted your friend request"
        case "declined":
            return "Declined your friend request"
        default:
            return "Updated your friend request"
        }
    }

    private func loadRequests() async {
        guard let supabase,
              let currentUserID = supabase.auth.currentUser?.id
        else {
            return
        }

        do {
            let incomingRows: [FriendRequestRow] = try await supabase
                .from("friend_requests")
                .select("requester_id, receiver_id, status")
                .eq("receiver_id", value: currentUserID.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value

            let statusRows: [FriendRequestRow] = try await supabase
                .from("friend_requests")
                .select("requester_id, receiver_id, status")
                .eq("requester_id", value: currentUserID.uuidString)
                .in("status", values: ["accepted", "declined"])
                .execute()
                .value

            if !statusRows.isEmpty {
                try await supabase
                    .from("friend_requests")
                    .delete()
                    .eq("requester_id", value: currentUserID.uuidString)
                    .in("status", values: ["accepted", "declined"])
                    .execute()
            }

            let profileIDs = Set(
                incomingRows.map { $0.requesterID } + statusRows.map { $0.receiverID }
            )

            if profileIDs.isEmpty {
                await MainActor.run {
                    requests = []
                }
                return
            }

            let profiles: [UserProfile] = try await supabase
                .from("onboarding")
                .select()
                .in("id", values: profileIDs.map { $0.uuidString })
                .execute()
                .value

            let profilesByID = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            let incomingItems = incomingRows.map { row in
                FriendRequestItem(
                    requesterID: row.requesterID,
                    receiverID: row.receiverID,
                    status: row.status,
                    kind: .incoming,
                    profile: profilesByID[row.requesterID]
                )
            }
            let statusItems = statusRows.map { row in
                FriendRequestItem(
                    requesterID: row.requesterID,
                    receiverID: row.receiverID,
                    status: row.status,
                    kind: .statusUpdate,
                    profile: profilesByID[row.receiverID]
                )
            }

            await MainActor.run {
                requests = incomingItems + statusItems
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
            let pair = orderedFriendPair(currentUserID: currentUserID, otherUserID: request.requesterID)
            try await supabase
                .from("friends")
                .insert(
                    FriendInsert(userID: pair.userID, friendID: pair.friendID)
                )
                .execute()

            try await supabase
                .from("friend_requests")
                .update(["status": "accepted"])
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
                .update(["status": "declined"])
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

    private func orderedFriendPair(
        currentUserID: UUID,
        otherUserID: UUID
    ) -> (userID: UUID, friendID: UUID) {
        if currentUserID.uuidString <= otherUserID.uuidString {
            return (currentUserID, otherUserID)
        }
        return (otherUserID, currentUserID)
    }
}

#Preview {
    BellView()
}
