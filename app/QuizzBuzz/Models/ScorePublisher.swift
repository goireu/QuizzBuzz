//
//  ScorePublisher.swift
//  QuizzBuzz
//
//  Created by Greg DT on 15/10/2022.
//

import Foundation
import CocoaMQTT

class ScorePublisher {
    let mqtt = CocoaMQTT(clientID: "25874af4-b2bf-4a00-b799-5b15909bada6", host: "iot.fr-par.scw.cloud", port: 1883)
    
    private var scorePayload = [UInt8]()
    
    func publishScores(buzzers: [Buzzer]) {
        encodeScores(buzzers: buzzers)

        switch mqtt.connState {
        case CocoaMQTTConnState.disconnected:
            print("MQTT CONNECT ATTEMPT...")
            mqtt.autoReconnect = true
            mqtt.didConnectAck = { mqtt, ack in
                print("MQTT CONNECTED")
                self.doPublish()
            }
            if mqtt.connect() == false {
                print("MQTT CONNECT FAILED")
            }
        case CocoaMQTTConnState.connecting:
            print("MQTT CONNECT IN PROGRESS, SKIP SCORE PUBLISHING")
        case CocoaMQTTConnState.connected:
            doPublish()
        }
    }
    
    private func doPublish() {
        print("PUBLISHING SCORES")
        mqtt.publish(CocoaMQTTMessage(topic: "scores", payload: scorePayload, qos: CocoaMQTTQoS.qos0, retained: true))
    }
    
    private func encodeScores(buzzers: [Buzzer]) {
        var buzzData = [String: Int]()
        for buzzer in buzzers {
            if buzzer.teamPlaying {
                buzzData[buzzer.teamName] = buzzer.teamPointsInt
            }
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: buzzData, options: .prettyPrinted)
            scorePayload = [UInt8](jsonData)
        } catch {
            print("COULDN'T ENCODE SCORES FOR PUBLISHING: \(error.localizedDescription)")
        }
    }
}
