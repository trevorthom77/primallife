import SwiftUI
import Supabase

@main
struct primallifeApp: App {
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://fefucqrztvepcbfjikrq.supabase.co")!,
        supabaseKey: "sb_publishable_2AWQG4a-U37T-pgp5FYnJA_28ymb116"
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView(supabase: supabase)
        }
    }
}
