//
//  Scan.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import Foundation
import SwiftData

@Model
final class PairedScanSession {
    @Attribute(.unique) var id: UUID
    var name: String
    var timestamp: Date
    
    // pointers: These just tell RealityKit where to look on the SSD
    var objFilename: String
    var faceFilename: String
    
    var emotion:String
    var emoji:String?
    
    
    @Transient
    var objURL: URL {
        //this part isn't saved, instead calling session.url calls this in real time and returns
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(objFilename)
    }

    @Transient
    var faceURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(faceFilename)
    }
    
    
    init(id: UUID = UUID(), name: String, timestamp: Date = Date(), objFilename:String, faceFilename:String, emotion:String, emoji:String) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.objFilename = objFilename
        self.faceFilename = faceFilename
        self.emotion = emotion
        self.emoji = emoji
    }
}
