import SwiftData
import SwiftUI

@main
struct SkillGomokuApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PlayerProfileEntity.self,
            PersistedMatchEntity.self,
            MatchRecordEntity.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
