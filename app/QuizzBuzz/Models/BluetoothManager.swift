//
//  Created by Artem Novichkov on 31.05.2021.
//

import Combine
import CoreBluetooth
import SwiftUI

struct BtBuzzer {
    let peripheral: CBPeripheral
    var blinkCharacteristic: CBCharacteristic?
}

final class BluetoothManager: NSObject {
    
    static let shared: BluetoothManager = .init()
    
    var stateSubject: PassthroughSubject<CBManagerState, Never> = .init()
    var connectedSubject: PassthroughSubject<UUID, Never> = .init()
    var disconnectedSubject: PassthroughSubject<UUID, Never> = .init()
    var batteryVoltageSubject: PassthroughSubject<(UUID, Double), Never> = .init()
    var rssiSubject: PassthroughSubject<(UUID, Int), Never> = .init()
    var buzzSubject: PassthroughSubject<UUID, Never> = .init()
    
    private var centralManager: CBCentralManager!
    private var discoveredDevices: [UUID: BtBuzzer] = [:]

    
    //MARK: - Operations
    
    func start() {
        centralManager = .init(delegate: self, queue: .main)
    }
    
    func scan() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "0x4242")], options: nil)
            discoveredDevices.forEach { (_, btBuzzer) in
                btBuzzer.peripheral.readRSSI()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.scan()
            }
        }
    }
    
    func connect(_ peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager.connect(peripheral)
    }
    
    private func _ledControl(identifier: UUID, blinkCount: UInt8) {
        guard let btBuzzer = discoveredDevices[identifier] else { return }
        guard let blinkCharacteristic = btBuzzer.blinkCharacteristic else { return }
        btBuzzer.peripheral.writeValue(Data([blinkCount]), for: blinkCharacteristic, type: .withoutResponse)
        print("Led control \(blinkCount)")
    }

    func blink(identifier: UUID, blinkCount: Int) {
        guard blinkCount > 0 && blinkCount < 0xFF else { return }
        _ledControl(identifier: identifier, blinkCount: UInt8(blinkCount))
    }
    func ledOn(identifier: UUID) {
        _ledControl(identifier: identifier, blinkCount: 0xFF)
    }
    func ledOff(identifier: UUID) {
        _ledControl(identifier: identifier, blinkCount: 0)
    }
}

// MARK: - Bluetooth Manager events
extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateSubject.send(central.state)
        
        switch central.state {
        case .poweredOff:
            discoveredDevices.removeAll()
            print("New BT central state: OFF")
        case .poweredOn:
            discoveredDevices.removeAll()
            print("New BT central state: ON")
            self.scan()
        case .unsupported:
            print("New BT central state: unsupported")
        case .unauthorized:
            print("New BT central state: unauthorized")
        case .unknown:
            print("New BT central state: unknown")
        case .resetting:
            print("New BT central state: resetting")
        @unknown default:
            print("Unknown BT central state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if discoveredDevices[peripheral.identifier] == nil {
            print("Discovered peripheral: \(peripheral.description) RSSI \(RSSI.stringValue) AdvertisementData: \(advertisementData)")
            discoveredDevices[peripheral.identifier] = BtBuzzer(peripheral: peripheral)
            centralManager.connect(peripheral)
            // TODO: handle connection failures and disconnections
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedSubject.send(peripheral.identifier)
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let err = error {
            print("didDisconnectPeripheral error: \(err.localizedDescription)")
            //return
        }
        if discoveredDevices[peripheral.identifier] != nil {
            discoveredDevices.removeValue(forKey: peripheral.identifier)
            disconnectedSubject.send(peripheral.identifier)
        }
    }
}

// MARK: - Bluetooth Peripheral events
extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            print("didDiscoverServices error: \(err.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            print("didDiscoverCharacteristicsFor error: \(err.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else {
            return
        }
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.uuid == CBUUID(string: "4244") {
                if discoveredDevices[peripheral.identifier] != nil {
                    discoveredDevices[peripheral.identifier]!.blinkCharacteristic = characteristic
                }
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("didUpdateValueFor error: \(err.localizedDescription)")
            return
        }
        switch characteristic.uuid {
        case CBUUID(string: "2A19"):
            guard let charValue = characteristic.value else { return }
            guard charValue.count > 0 else { return }
            batteryVoltageSubject.send((peripheral.identifier, Double(charValue[0]) / 10))
        case CBUUID(string: "4243"):
            buzzSubject.send(peripheral.identifier)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let err = error {
            print("didReadRSSI error: \(err.localizedDescription)")
            return
        }
        rssiSubject.send((peripheral.identifier, RSSI.intValue))
    }
}
