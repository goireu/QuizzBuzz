//
//  BuzzerData.swift
//  bttest
//
//  Created by Greg DT on 19/03/2022.
//

// If I turn those into ObservableObject classes and use @Published wrappers SwiftUI will fail at
// recognizing updates, couldn't find why. I thus used structs.

import Foundation
import SwiftUI

extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            return (0, 0, 0, 0)
        }

        return (r, g, b, o)
    }
}

struct TeamColor : Codable {
    var r: Double
    var g: Double
    var b: Double
    
    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
    init(color: Color) {
        self.r = color.components.red
        self.g = color.components.green
        self.b = color.components.blue
    }
    var color: Color {
        return Color(red: r, green: g, blue: b)
    }
}

struct BuzzerData: Codable {
    var id: UUID
    var teamName: String
    var teamPoints: String
    var teamColor: TeamColor
    var teamPlaying: Bool
    var teamSound: String
    var buzzCount: Int

    init(id: UUID, teamName: String, teamPoints: String, teamColor: TeamColor, teamPlaying:Bool, teamSound: String, buzzCount: Int) {
        self.id = id
        self.teamName = teamName
        self.teamPoints = teamPoints
        self.teamColor = teamColor
        self.teamPlaying = teamPlaying
        self.teamSound = teamSound
        self.buzzCount = 0
    }
}

struct Buzzer : Identifiable {
    let id: UUID // Use bluetooth ID
    var teamName: String
    var teamPoints: String // Required by editor
    var teamColor: Color
    var teamPlaying: Bool
    var teamSound: String
    var buzzCount: Int

    var batteryVoltage: Double?
    var rssi: Int?
    var hasBuzzed: Bool
    var isConnected: Bool
    
    // Inits Buzzer from discovery
    init(id: UUID) {
        self.id = id
        self.teamName = String(id.uuidString.prefix(20))
        self.teamPoints = "0"
        self.teamColor = Color.random
        self.teamPlaying = true // TODO: change me
        self.teamSound = ""
        self.buzzCount = 0
        self.hasBuzzed = false
        self.isConnected = true
    }
    
    // Inits Buzzer from storage
    init(data: BuzzerData) {
        self.id = data.id
        self.teamName = data.teamName
        self.teamPoints = data.teamPoints
        self.teamColor = data.teamColor.color
        self.teamPlaying = data.teamPlaying
        self.teamSound = data.teamSound
        self.buzzCount = data.buzzCount
        self.hasBuzzed = false
        self.isConnected = false
    }
    // Exports Buzzer to storage
    func data() -> BuzzerData {
        return BuzzerData(id: self.id, teamName: self.teamName, teamPoints: self.teamPoints, teamColor: TeamColor(color: self.teamColor), teamPlaying: self.teamPlaying, teamSound: self.teamSound, buzzCount: self.buzzCount)
    }
    
    mutating func setConnected(_ isConnected: Bool) {
        self.isConnected = isConnected
    }
    mutating func updateBatteryVolatge(batteryVoltage: Double) {
        self.batteryVoltage = batteryVoltage
    }
    mutating func updateRssi(rssi: Int) {
        self.rssi = rssi
    }
    mutating func addPoints(points: Int) {
        if let curPoints = Int(self.teamPoints) {
            self.teamPoints = String(curPoints + points)
        } else {
            self.teamPoints = "0"
        }
    }
    mutating func buzzCountIncrement() {
        self.buzzCount += 1
    }

    var signal: String {
        guard isConnected else { return "déconnecté" }
        guard let db = rssi else { return "?? dB"}
        return "\(db) dB"
    }
    
    var battery: String {
        guard let voltage = batteryVoltage else { return "?? V"}
        return "\(voltage) V"
    }

    var teamPointsInt: Int {
        guard let points = Int(teamPoints) else { return 0 }
        return points
    }
}

extension Buzzer {
    static let sampleData: [Buzzer] =
    [
        Buzzer(id: UUID()),
        Buzzer(id: UUID()),
        Buzzer(id: UUID())
    ]
}

struct BuzzerPool {
    var buzzers: [Buzzer] = [] {
        didSet {
            save()
        }
    }
    var lastPress: Buzzer? // Last received buzzer pressed message (used for identification)
    var lastBuzz: Buzzer? // Same as above, except it will be updated only if value is nil (used for stopping the music)
    var buzzPending: Bool // TODO: here because sheet isPresenting complains if not a $Bool, might be improved
    var allowMultipleBuzz: Bool
    var handicapInMs: Float // Add a delay when a buzz is received, delay is: (buzzerPoints - maxPoints) * handicapInMs.
    
    var buzzCount: Int {
        return buzzers.filter { $0.hasBuzzed }.count
    }
    var connectedBuzzers: [Buzzer] {
        return buzzers.filter { $0.isConnected }
    }
    var playingBuzzers: [Buzzer] {
        return buzzers.filter { $0.teamPlaying }
    }
    
    init(buzzers: [Buzzer] = []) {
        self.buzzers = buzzers
        self.buzzPending = false
        self.allowMultipleBuzz = false
        self.handicapInMs = 0
    }
    
    private var _plistData = Data()
    mutating func save() {
        let buzzerData = buzzers.map { $0.data() }
        if let data = try? PropertyListEncoder().encode(buzzerData) {
            if data != _plistData {
                _plistData = data
                UserDefaults.standard.set(data, forKey: "buzzers")
                print("Saved \(buzzerData.count) buzzers")
            }
        }
    }
    mutating func load() {
        if let data = UserDefaults.standard.data(forKey: "buzzers") {
            _plistData = data
            guard let buzzerData = try? PropertyListDecoder().decode([BuzzerData].self, from: data) else { return }
            self.buzzers = buzzerData.map { Buzzer(data: $0) }
            self.buzzers.forEach { print("\($0.teamName): \($0.id)")}
        }
        print("Loaded \(self.buzzers.count) buzzers")
    }

    mutating func buzzerIndex(buzzerID: UUID, createOnMissing: Bool = false) -> Int? {
        if let idx = buzzers.firstIndex(where: { $0.id == buzzerID }) {
            return idx
        }
        if createOnMissing {
            buzzers.append(Buzzer(id: buzzerID))
            if let idx = buzzers.firstIndex(where: { $0.id == buzzerID }) {
                return idx
            }
        }
        return nil
    }
    
    mutating func foundBuzzer(buzzerID: UUID) {
        if let idx = buzzerIndex(buzzerID: buzzerID, createOnMissing: true) {
            buzzers[idx].setConnected(true)
        }
    }
    mutating func lostBuzzer(buzzerID: UUID) {
        if let idx = buzzerIndex(buzzerID: buzzerID, createOnMissing: true) {
            buzzers[idx].setConnected(false)
        }
    }
    mutating func removeBuzzer(buzzerID: UUID) {
        buzzers.removeAll(where: { $0.id == buzzerID })
    }
    
    mutating func updateRSSI(buzzerID: UUID, rssi: Int) {
        if let idx = buzzerIndex(buzzerID: buzzerID, createOnMissing: true) {
            buzzers[idx].updateRssi(rssi: rssi)
        }
    }
    mutating func updateBatteryVolatge(buzzerID: UUID, batteryVoltage: Double) {
        if let idx = buzzerIndex(buzzerID: buzzerID, createOnMissing: true) {
            buzzers[idx].updateBatteryVolatge(batteryVoltage: batteryVoltage)
        }
    }
    mutating func buzz(buzzerID: UUID, isPlaying: Bool, handicapFinished: Bool) {
        guard let idx = buzzerIndex(buzzerID: buzzerID, createOnMissing: true) else { return }
        
        buzzers[idx].buzzCountIncrement()
        // Ignore buzzer while music is stopped
        if isPlaying == false {
            return
        }
        // Not allowed to play during handicap time
        if handicapFinished == false {
            return
        }
        // Buzz is allowed, process it
        lastPress = buzzers[idx]
        if !buzzers[idx].hasBuzzed && !buzzPending {
            lastBuzz = buzzers[idx]
            if !allowMultipleBuzz {
                buzzers[idx].hasBuzzed = true
            }
            buzzPending = true
        }
    }
    
    mutating func clearLastBuzz(addPoints: Int) {
        if let buzzer = lastBuzz {
            if let idx = buzzerIndex(buzzerID: buzzer.id) {
                buzzers[idx].addPoints(points: addPoints)
            }
        }
        lastBuzz = nil
        buzzPending = false
    }
    
    mutating func setAllBuzzed() {
        for (idx, _) in buzzers.enumerated() {
            buzzers[idx].hasBuzzed = true
        }
    }

    mutating func resetBuzzs(clearScores: Bool = false) {
        for (idx, _) in buzzers.enumerated() {
            buzzers[idx].hasBuzzed = false
            if clearScores {
                buzzers[idx].teamPoints = "0"
                buzzers[idx].buzzCount = 0
            }
        }
    }
}

extension BuzzerPool {
    static let sampleData = BuzzerPool(buzzers:
                                        [
                                            Buzzer(id: UUID()),
                                            Buzzer(id: UUID()),
                                            Buzzer(id: UUID())
                                        ])
}

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
