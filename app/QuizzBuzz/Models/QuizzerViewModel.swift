//
//  Created by Artem Novichkov on 31.05.2021.
//

import SwiftUI
import CoreBluetooth
import Combine

final class QuizzerViewModel: ObservableObject {
    
    @Published var btState: CBManagerState = .unknown
    @Published var buzzerPool: BuzzerPool
    
    private lazy var manager: BluetoothManager = .shared
    private lazy var cancellables: Set<AnyCancellable> = .init()

    init(buzzerPool: BuzzerPool = BuzzerPool()) {
        self.buzzerPool = buzzerPool
    }
    
    private var isPlaying = false
    
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

    private var started = false;
    func start(playingSubject: PassthroughSubject<Bool, Never>) {
        guard started == false else { return }
        buzzerPool.load()

        // Remote is playing music
        playingSubject.sink { [weak self] in
            self?.isPlaying = $0
            print("REMOTE \($0 ? "" : "NOT") PLAYING")
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
                self?.buzzerPool.buzz(buzzerID: $0)
            }
            print("DEVICE \($0) BUZZED!")
        }
        .store(in: &cancellables)

        manager.start()
        started = true
    }
}
