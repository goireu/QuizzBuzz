//
//  BuzzerEditView.swift
//  bttest
//
//  Created by Greg DT on 24/03/2022.
//

import SwiftUI
import Combine
import AudioToolbox

struct BuzzerEditView: View {
    @Binding var buzzer: Buzzer
    @State var soundName = "" // Picker doesn't close if we directly use buzzer.teamSound
    
    var body: some View {
        Form {
            Section(header: Text("Equipe")) {
                TextField("Nom", text: $buzzer.teamName)
                HStack {
                    Text("Points: ").font(.headline)
                    TextField("Points", text: $buzzer.teamPoints)
                        .keyboardType(.numberPad)
                        .onReceive(Just(buzzer.teamPoints)) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                self.buzzer.teamPoints = filtered
                            }
                        }
                }
                HStack {
                    Text("Couleur:").font(.headline)
                    ColorPicker("Color", selection: $buzzer.teamColor, supportsOpacity: false)
                        .font(.headline)
                        .labelsHidden()
                }
            }
            Section(header: Text("Jingle")) {
                Picker("Choix du jingle", selection: $soundName) {
                    ForEach(AssetSounds.instance.names.sorted(), id: \.self) { s in
                        Text(s)
                    }
                }.onChange(of: soundName) { (name) in
                    buzzer.teamSound = soundName
                }
                HStack {
                    Spacer()
                    Button("Ecouter") {
                        AssetSounds.instance.play(name: buzzer.teamSound)
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    Spacer()
                }
            }
            Section(header: Text("Jeu")) {
                Toggle("Buzzer en jeu", isOn: $buzzer.teamPlaying)
            }
        }
        .onAppear() {
            if soundName == "" {
                soundName = buzzer.teamSound
            }
        }
    }
}

struct BuzzerEditView_Previews: PreviewProvider {
    static var previews: some View {
        BuzzerEditView(buzzer: .constant(Buzzer.sampleData[0]))
    }
}
