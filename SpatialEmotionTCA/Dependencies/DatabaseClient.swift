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
    //added asynchrony, may cause issues 
    var saveSession: @Sendable (_ scanID:UUID, _ objURL: URL, _ faceURL: URL) async throws -> Void
    var deleteSession: @Sendable(_ scanId:UUID, _ objURL: URL, _ faceURL: URL) async throws -> Void
    var fetchAllSessions: @Sendable() throws -> [PairedScanSession]
}

//potentially need modelactor?
extension DatabaseClient: DependencyKey {
    static let liveValue = Self(
        saveSession: {scanId, objURL, faceURL in //save from camera feature
            //Connect to the existing SQLite database file
            let container = try ModelContainer(for: PairedScanSession.self)
            
            // Create a fresh context for this specific background task
            let context = ModelContext(container)
            
            // Initialize data model
            let now = Date.now
            let session = PairedScanSession(
                id:scanId,
                name: "Scan \(Date().formatted(date: .abbreviated, time: .shortened))",
                scanOneURL: objURL,
                scanTwoURL: faceURL
            )
            
            context.insert(session)
            try context.save()
        },
        
        deleteSession: {scanId, objUrl, faceUrl in //delete from scan review
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
        fetchAllSessions: { //get all for scan history
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
