import SwiftUI
import Combine
import Supabase

private let myTripsDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

struct Trip: Decodable, Identifiable {
    let id: UUID
    let userID: UUID
    let destination: String
    let checkIn: Date
    let returnDate: Date
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case destination
        case checkIn = "check_in"
        case returnDate = "return_date"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        destination = try container.decode(String.self, forKey: .destination)

        let checkInString = try container.decode(String.self, forKey: .checkIn)
        guard let checkInDate = myTripsDateFormatter.date(from: checkInString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.checkIn], debugDescription: "Invalid check-in date format")
            )
        }
        checkIn = checkInDate

        let returnDateString = try container.decode(String.self, forKey: .returnDate)
        guard let decodedReturnDate = myTripsDateFormatter.date(from: returnDateString) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.returnDate], debugDescription: "Invalid return date format")
            )
        }
        returnDate = decodedReturnDate

        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

struct NewTrip: Encodable {
    let userID: UUID
    let destination: String
    let checkIn: Date
    let returnDate: Date
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case destination
        case checkIn = "check_in"
        case returnDate = "return_date"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(destination, forKey: .destination)
        try container.encode(myTripsDateFormatter.string(from: checkIn), forKey: .checkIn)
        try container.encode(myTripsDateFormatter.string(from: returnDate), forKey: .returnDate)
    }
}

@MainActor
final class MyTripsViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var error: String?

    func loadTrips(supabase: SupabaseClient?) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }

        do {
            let fetchedTrips: [Trip] = try await supabase
                .from("mytrips")
                .select()
                .eq("user_id", value: "\(userID)")
                .order("created_at", ascending: false)
                .execute()
                .value

            trips = fetchedTrips
            error = nil
        } catch {
            self.error = "Unable to load trips."
        }
    }

    func addTrip(destination: String, checkIn: Date, returnDate: Date, supabase: SupabaseClient?) async {
        guard let supabase, let userID = supabase.auth.currentUser?.id else { return }
        let payload = NewTrip(
            userID: userID,
            destination: destination,
            checkIn: checkIn,
            returnDate: returnDate
        )

        do {
            try await supabase
                .from("mytrips")
                .insert(payload)
                .execute()

            await loadTrips(supabase: supabase)
        } catch {
            self.error = "Unable to add trip."
        }
    }
}

struct MyTripsView: View {
    @Environment(\.supabaseClient) var supabase
    @StateObject private var viewModel = MyTripsViewModel()
    @State private var tribeImageURL: URL?
    @State private var secondTribeImageURL: URL?
    @State private var sunImageURL: URL?
    @State private var groundingImageURL: URL?
    @State private var isShowingTrips = false
    @State private var isShowingTribeTrips = false
    @State private var selectedTripIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Trips")
                            .font(.customTitle)
                            .foregroundStyle(Colors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingTrips = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Colors.accent)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "plus")
                                    .foregroundStyle(Colors.tertiaryText)
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Colors.background)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Upcoming Trips")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            
                            TabView(selection: $selectedTripIndex) {
                                HStack(spacing: 0) {
                                    TravelCard(showsAttribution: true)
                                    Spacer()
                                }
                                .tag(0)
                                
                                HStack(spacing: 0) {
                                    TravelCard(
                                        flag: "🇧🇸",
                                        location: "Bahamas",
                                        dates: "Mar 2–9",
                                        imageQuery: "Bahamas beach",
                                        showsAttribution: true)
                                    Spacer()
                                }
                                .tag(1)
                            }
                            .frame(height: 180)
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .sensoryFeedback(.impact(weight: .medium), trigger: selectedTripIndex)
                            
                            HStack(spacing: 18) {
                                Image("airplane")
                                    .renderingMode(.template)
                                    .foregroundStyle(selectedTripIndex == 0 ? Colors.accent : Colors.secondaryText)
                                    
                                Image("airplane")
                                    .renderingMode(.template)
                                    .foregroundStyle(selectedTripIndex == 1 ? Colors.accent : Colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            
                            HStack {
                                Text("Costa Rica Tribes")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            .padding(.top, 16)
                            
                            NavigationLink {
                                TribesSocialView(
                                    imageURL: tribeImageURL,
                                    title: "Party Tonight Costa Rica",
                                    location: "Costa Rica",
                                    flag: "🇨🇷",
                                    date: "Dec 5–9, 2025"
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: tribeImageURL) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Colors.card
                                        }
                                        .frame(width: 88, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Party Tonight Costa Rica")
                                                .font(.travelDetail)
                                                .foregroundStyle(Colors.primaryText)
                                            
                                            HStack(spacing: 6) {
                                                Text("🇨🇷")
                                                Text("Costa Rica")
                                                    .font(.travelDetail)
                                                    .foregroundStyle(Colors.secondaryText)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Colors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                    HStack(spacing: -8) {
                                        Image("profile1")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                        
                                        Image("profile2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                        
                                        Image("profile3")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }
                                        
                                        ZStack {
                                            Circle()
                                                .fill(Colors.background)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }
                                            
                                            Text("67+")
                                                .font(.custom(Fonts.semibold, size: 12))
                                                .foregroundStyle(Colors.primaryText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                            .buttonStyle(.plain)
                            .task {
                                tribeImageURL = await UnsplashService.fetchImage(for: "Costa Rica beach")
                            }

                            NavigationLink {
                                TribesSocialView(
                                    imageURL: secondTribeImageURL,
                                    title: "Rainforest Tribe Costa Rica",
                                    location: "Costa Rica",
                                    flag: "🇨🇷",
                                    date: "Dec 5–9, 2025"
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: secondTribeImageURL) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Colors.card
                                        }
                                        .frame(width: 88, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Rainforest Tribe Costa Rica")
                                                .font(.travelDetail)
                                                .foregroundStyle(Colors.primaryText)

                                            HStack(spacing: 6) {
                                                Text("🇨🇷")
                                                Text("Costa Rica")
                                                    .font(.travelDetail)
                                                    .foregroundStyle(Colors.secondaryText)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(Colors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))

                                    HStack(spacing: -8) {
                                        Image("profile1")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        Image("profile2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        Image("profile3")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay {
                                                Circle()
                                                    .stroke(Colors.card, lineWidth: 3)
                                            }

                                        ZStack {
                                            Circle()
                                                .fill(Colors.background)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Circle()
                                                        .stroke(Colors.card, lineWidth: 3)
                                                }

                                            Text("54+")
                                                .font(.custom(Fonts.semibold, size: 12))
                                                .foregroundStyle(Colors.primaryText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                            .buttonStyle(.plain)
                            .task {
                                secondTribeImageURL = await UnsplashService.fetchImage(for: "Costa Rica jungle")
                            }

                            Button(action: {
                                isShowingTribeTrips = true
                            }) {
                                Text("Add Tribe")
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.tertiaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Colors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            
                            HStack {
                                Text("Adventures")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            .padding(.top, 24)
                            
                            HStack(spacing: 12) {
                                AsyncImage(url: sunImageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Colors.card
                                }
                                .frame(width: 88, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sun")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)
                                    
                                    Text("Rare")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.tertiaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Colors.accent.opacity(0.6))
                                        )
                                }
                                
                                Spacer()
                                
                                Image("boat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                            }
                            .padding(12)
                            .frame(height: 96)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .task {
                                sunImageURL = await UnsplashService.fetchImage(for: "sunset beach")
                            }

                            HStack(spacing: 12) {
                                AsyncImage(url: groundingImageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Colors.card
                                }
                                .frame(width: 88, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Grounding")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.primaryText)

                                    Text("Legendary")
                                        .font(.travelDetail)
                                        .foregroundStyle(Colors.tertiaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Colors.legendary)
                                        )
                                }

                                Spacer()

                                Image("boat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                            }
                            .padding(12)
                            .frame(height: 96)
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .task {
                                groundingImageURL = await UnsplashService.fetchImage(for: "forest trail")
                            }

                            HStack {
                                Text("Travelers going")
                                    .font(.travelTitle)
                                    .foregroundStyle(Colors.primaryText)
                                
                                Spacer()
                                
                                Button("See All") { }
                                    .font(.travelDetail)
                                    .foregroundStyle(Colors.accent)
                            }
                            .padding(.top, 16)
                            
                            HStack(spacing: 12) {
                                Image("profile7")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Ava")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)
                                        
                                        Text("27")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text("🇲🇽")
                                        Text("Mexico")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            HStack(spacing: 12) {
                                Image("profile8")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Leo")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        Text("25")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }

                                    HStack(spacing: 8) {
                                        Text("🇧🇷")
                                        Text("Brazil")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            HStack(spacing: 12) {
                                Image("profile9")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.card, lineWidth: 3)
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text("Maya")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.primaryText)

                                        Text("31")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }

                                    HStack(spacing: 8) {
                                        Text("🇨🇷")
                                        Text("Costa Rica")
                                            .font(.travelDetail)
                                            .foregroundStyle(Colors.secondaryText)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 96)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingTrips) {
                TripsView()
            }
            .navigationDestination(isPresented: $isShowingTribeTrips) {
                TribeTripsView()
            }
        }
        .task {
            await viewModel.loadTrips(supabase: supabase)
        }
    }
}

#Preview {
    MyTripsView()
}
