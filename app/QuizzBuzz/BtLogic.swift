//
//  btLogic.swift
//  bttest
//
//  Created by Greg DT on 14/03/2022.
//

import Foundation
import CoreBluetooth

class BtLogic : NSObject, ObservableObject {
    @Published var buzzerPool = BuzzerPool()
    
    private var centralManager: CBCentralManager!
    private var discoveredDevices: [UUID: CBPeripheral] = [:]
    
    override init() {
        super.init()
        centralManager = .init(delegate: self, queue: .main)
    }
    
    func start() {
    }
    func stop() {
        //centralManager.stopScan()
    }
    func clear() {
        discoveredDevices.removeAll()
        buzzerPool.buzzers.removeAll()
    }
}

extension BtLogic: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            self.clear()
            print("New BT central state: OFF")
        case .poweredOn:
            self.clear()
            print("New BT central state: ON")
            self.doScan()
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
    
    func doScan() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "0x4242")], options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.doScan()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if discoveredDevices[peripheral.identifier] == nil {
            print("Discovered peripheral: \(peripheral.description) RSSI \(RSSI.stringValue) AdvertisementData: \(advertisementData)")
            discoveredDevices[peripheral.identifier] = peripheral
            centralManager.connect(peripheral)
            // TODO: handle connection failures and disconnections
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.description)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        peripheral.readRSSI()
        if !buzzerPool.buzzers.contains(where: { $0.id == peripheral.identifier }) {
            buzzerPool.buzzers.append(Buzzer(id: peripheral.identifier))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let err = error {
            print("didDisconnectPeripheral error: \(err.localizedDescription)")
            //return
        }
        if discoveredDevices[peripheral.identifier] != nil {
            discoveredDevices.removeValue(forKey: peripheral.identifier)
            buzzerPool.buzzers.removeAll(where: { $0.id == peripheral.identifier })
        }
    }
}

extension BtLogic: CBPeripheralDelegate {
    
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
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        //print("Found the following characteristics for \(peripheral.description): \(characteristics.description)")
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
          if let idx = buzzerPool.buzzers.firstIndex(where: { $0.id == peripheral.identifier }) {
              buzzerPool.buzzers[idx].updateBatteryVolatge(batteryVoltage: Double(charValue[0]) / 10)
          }
          //print("Battery \(charValue[0])")
      case CBUUID(string: "4243"):
          print("BUZZ!")
          buzzerPool.buzz(buzzerID: peripheral.identifier)
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid.uuidString)")
      }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let err = error {
            print("didReadRSSI error: \(err.localizedDescription)")
            return
        }
        if let idx = buzzerPool.buzzers.firstIndex(where: { $0.id == peripheral.identifier }) {
            buzzerPool.buzzers[idx].updateRssi(rssi: RSSI.intValue)
        }
        //print("RSSI \(RSSI.intValue)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.discoveredDevices[peripheral.identifier] != nil {
                peripheral.readRSSI()
            }
        }
    }
}
