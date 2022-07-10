//
//  Model.swift
//  Hydration Watch App
//
//  Created by Roland Kajatin on 17/06/2022.
//

import SwiftUI
import Foundation

struct Model: Codable {
    var target: Float = 3000
    var records = Array<HydrationRecord>()
    var color = Color.indigo
    var timeToDrink = false
    var timeToDrinkNotification = false
    var hydrationHistory: Double = 7
    var notificationInterval: Double = 3600
    
    static let colors = [Color.brown, Color.indigo, Color.blue, Color.teal, Color.green, Color.yellow, Color.orange, Color.red, Color.pink]

    init() { }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(Model.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try Model(json: data)
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    mutating func restoreDefaults() {
        target = 3000
        color = Color.indigo
        timeToDrink = false
        timeToDrinkNotification = false
        notificationInterval = 3600
    }

    struct HydrationRecord: Identifiable, Equatable, Codable {
        var id: Date { date }
        let date: Date
        let volume: Float
    }
}

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case color
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorString = try container.decode(String.self, forKey: .color)
        if let color = Model.colors.first(where: { $0.description == colorString }) {
            self = color
        } else {
            self = .indigo
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.description, forKey: .color)
    }
}
