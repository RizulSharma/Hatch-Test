//
//  ARData.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 31/03/22.
//

import ARKit

struct ARData {
    var worldMap: ARWorldMap?
}

extension ARData: Codable {
    enum CodingKeys: String, CodingKey {
        case worldMap
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let worldMapData = try container.decode(Data.self, forKey: .worldMap)
        worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: worldMapData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let worldMap = worldMap {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try container.encode(colorData, forKey: .worldMap)
        }
    }
}
