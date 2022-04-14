//
//  SystemSounds.swift
//  QuizzBuzz
//
//  Created by Greg DT on 30/03/2022.
//

import Foundation
import AudioToolbox

class AssetSounds {
    static public let instance = AssetSounds()

    public let names: [String]
    private let sounds: [String:SystemSoundID]

    private let fileManager = FileManager.default
    private let bundleURL = Bundle.main.bundleURL.appendingPathComponent("Jingles.bundle")
    
    init() {
        var sounds: [String:SystemSoundID] = [:]
        var names: [String] = []
        var soundID: SystemSoundID = 0

        do {
            let contents = try fileManager.contentsOfDirectory(at: self.bundleURL, includingPropertiesForKeys: [URLResourceKey.nameKey], options: .skipsHiddenFiles)
            for item in contents {
                let name = String(item.lastPathComponent.split(separator: ".")[0])
                names.append(name)
                AudioServicesCreateSystemSoundID(item as CFURL, &soundID)
                sounds[name] = soundID
            }
        }
        catch let error as NSError {
            print(error)
        }
        self.names = names
        self.sounds = sounds
    }

    func play(name: String) {
        if let soundID = sounds[name] {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}
