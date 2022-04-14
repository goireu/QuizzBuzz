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
    /* Shouldn't be needed
     deinit {
     cancellables.cancel()
     }*/
    
    private var isPlaying = false
    
    func blink() {
        if let buzzer = buzzerPool.lastBuzz {
            manager.blink(identifier: buzzer.id)
        }
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
