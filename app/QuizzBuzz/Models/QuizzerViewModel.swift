//
//  Created by Artem Novichkov on 31.05.2021.
//

import SwiftUI
import CoreBluetooth
import Combine

final class QuizzerViewModel: ObservableObject {
    
    @Published var btState: CBManagerState = .unknown
    @Published var buzzerPool: BuzzerPool
    @Published var remote = SpotifyRemote()
    
    private lazy var manager: BluetoothManager = .shared
    private lazy var cancellables: Set<AnyCancellable> = .init()

    init(buzzerPool: BuzzerPool = BuzzerPool()) {
        self.buzzerPool = buzzerPool
    }
    
    private var isPlaying = false
    private var trackStartTime: Date = Date()
    
    func lastBuzzerLedBlink(blinkCount: Int) {
        if let buzzer = buzzerPool.lastBuzz {
            manager.blink(identifier: buzzer.id, blinkCount: blinkCount)
        }
    }
    func lastBuzzerLedOn() {
        if let buzzer = buzzerPool.lastBuzz {
            manager.ledOn(identifier: buzzer.id)
        }
    }
    func lastBuzzerLedOff() {
        if let buzzer = buzzerPool.lastBuzz {
            manager.ledOff(identifier: buzzer.id)
        }
    }
    func allBuzzerLedOn() {
        buzzerPool.buzzers.forEach { buzzer in
            manager.ledOn(identifier: buzzer.id)
        }
    }
    func allBuzzerLedOff() {
        buzzerPool.buzzers.forEach { buzzer in
            manager.ledOff(identifier: buzzer.id)
        }
    }

    func resetBuzzs(clearScores: Bool = false) {
        allBuzzerLedOff();
        // Reset internal state so they can play again
        buzzerPool.resetBuzzs(clearScores: clearScores)
    }
    
    func correctAnswer(addPoints: Int) {
        allBuzzerLedOn()
        buzzerPool.setAllBuzzed()
        buzzerPool.clearLastBuzz(addPoints: addPoints)
    }
    func wrongAnswer() {
        // No need to clear the hasBuzzed flag of the buzzer,
        // it was not set at buzz time if allowMultipleBuzz is true
        if buzzerPool.allowMultipleBuzz {
            lastBuzzerLedOff()
        } else {
            lastBuzzerLedOn()
        }
        buzzerPool.clearLastBuzz(addPoints: 0)
    }
    
    private var gameMinPoints: Int {
        // Compute minPoints
        var minPoints = 999999999 // Start with a very high number to make the calculus easier (ok, this aint perfect but will do the job)
        buzzerPool.playingBuzzers.forEach { buzzer in
            if buzzer.teamPointsInt < minPoints {
                minPoints = buzzer.teamPointsInt
            }
        }
        return minPoints
    }
    private func buzzerHandicapDelay(buzzerID: UUID) -> Double {
        guard let idx = buzzerPool.buzzerIndex(buzzerID: buzzerID) else { return 0 }
        return buzzerHandicapDelay(teamPointsInt: buzzerPool.buzzers[idx].teamPointsInt)
    }
    func buzzerHandicapDelay(teamPointsInt: Int) -> Double {
        let delay = Double(teamPointsInt - gameMinPoints) * Double(buzzerPool.handicapInMs / 1000)
        if delay < 0 {
            return 0
        }
        return delay
    }
    
    private func onNewTrack() {
        buzzerPool.resetBuzzs(clearScores: false)
        if buzzerPool.handicapInMs > 0 {
            // Store current time
            trackStartTime = Date()
            // Switch on/off leds and start timer for buzzers with handicap
            buzzerPool.playingBuzzers.forEach { buzzer in
                let handicapDelay = buzzerHandicapDelay(teamPointsInt: buzzer.teamPointsInt)
                // If there is a handicap delay, keep led on until delay is expired
                if (handicapDelay > 0) {
                    self.manager.ledOn(identifier: buzzer.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + handicapDelay) {
                        self.manager.ledOff(identifier: buzzer.id)
                    }
                }
                // Else, no handicap, switch off the led
                else {
                    self.manager.ledOff(identifier: buzzer.id)
                }
            }
        }
    }

    private var started = false;
    func start() {
        guard started == false else { return }
        started = true

        buzzerPool.load()

        // Remote is playing music
        remote.playingSubject.sink { [weak self] in
            self?.isPlaying = $0
            print("REMOTE \($0 ? "" : "NOT") PLAYING")
        }
        .store(in: &cancellables)
        
        // New track started, store timestamp, switch on 'X' leds, initiate handicap timers
        remote.newTrackSubject.sink { [weak self] in
            if $0 { // $0 is always true, I just don't know how to get rid of compiler error
                self?.onNewTrack()
            }
        }
        .store(in: &cancellables)

        // Manager state changed
        manager.stateSubject.sink { [weak self] state in
            self?.btState = state
        }
        .store(in: &cancellables)
        // New device connected
        manager.connectedSubject.sink { [weak self] in
            self?.buzzerPool.foundBuzzer(buzzerID: $0)
            print("DEVICE  \($0) CONNECTED")
        }
        .store(in: &cancellables)
        // New device connected
        manager.disconnectedSubject
            .sink { [weak self] in
                self?.buzzerPool.lostBuzzer(buzzerID: $0)
                print("DEVICE  \($0) DISCONNECTED")
            }
            .store(in: &cancellables)
        // Device RSSI update
        manager.rssiSubject.sink { [weak self] in
            let (id, rssi) = $0
            self?.buzzerPool.updateRSSI(buzzerID: id, rssi: rssi)
            print("DEVICE \(id) RSSI: \(rssi)")
        }
        .store(in: &cancellables)
        // Device battery update
        manager.batteryVoltageSubject.sink { [weak self] in
            let (id, batteryVoltage) = $0
            self?.buzzerPool.updateBatteryVolatge(buzzerID: id, batteryVoltage: batteryVoltage)
            print("DEVICE \(id) BATTERY: \(batteryVoltage)")
        }
        .store(in: &cancellables)
        // Device Buzz!
        manager.buzzSubject.sink { [weak self] in
            if self != nil && self!.isPlaying {
                // The buzzer is not allowed to buzz before its handicap time
                if self!.trackStartTime.timeIntervalSinceNow > self!.buzzerHandicapDelay(buzzerID: $0) {
                    self!.buzzerPool.buzz(buzzerID: $0)
                }
            }
            print("DEVICE \($0) BUZZED!")
        }
        .store(in: &cancellables)

        manager.start()
    }
}
