//
//  DatabaseClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/4/26.
//

import ComposableArchitecture
import Foundation
import SwiftData


struct DatabaseClient:Sendable {
    var saveSession: @Sendable (_ objURL: URL, _ faceURL: URL) throws -> Void
    var deleteSession: @Sendable(_ scanId:UUID, _ objURL: URL, _ faceURL: URL) throws -> Void
    var fetchAllSessions: @Sendable() throws -> [PairedScanSession]
    //fetch single session?
}

extension DatabaseClient: DependencyKey {
    static let liveValue = Self(
        saveSession: { objURL, faceURL in
            // 1. Connect to the existing SQLite database file
            let container = try ModelContainer(for: PairedScanSession.self)
            
            // 2. Create a fresh context for this specific background task
            let context = ModelContext(container)
            
            // 3. Initialize your data model
            let session = PairedScanSession(
                id:UUID(),
                name: "Scan \(Date().formatted(date: .abbreviated, time: .shortened))",
                scanOneURL: objURL,
                scanTwoURL: faceURL
            )
            
            context.insert(session)
            try context.save()
        },
        deleteSession: {scanId, objUrl, faceUrl in
            let fileManager = FileManager.default
            //delete from filemanager unless already removed
            try? fileManager.removeItem(at: objUrl)
            try? fileManager.removeItem(at: faceUrl)
            //Connect to SwiftData
            let container = try ModelContainer(for: PairedScanSession.self)
            let context = ModelContext(container)
            
           // Find the specific record and delete it
            let descriptor = FetchDescriptor<PairedScanSession>(predicate: #Predicate { $0.id == scanId })
            if let sessionToDelete = try context.fetch(descriptor).first {
                context.delete(sessionToDelete)
                try context.save()
            }
        },
        fetchAllSessions: {
            let container = try ModelContainer(for: PairedScanSession.self)
            let context = ModelContext(container)
            
            // Fetch all sessions, sorted by date (newest first)
            var descriptor = FetchDescriptor<PairedScanSession>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            return try context.fetch(descriptor)
        }
    )
}

extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
