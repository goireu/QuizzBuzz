//
//  AnswerView.swift
//  bttest
//
//  Created by Greg DT on 25/03/2022.
//

import SwiftUI

struct AnswerView: View {
    @Binding var buzzerPool: BuzzerPool
    @ObservedObject var remote: SpotifyRemote
    
    var body: some View {
        VStack {
            Label("Buzz!", systemImage: "hands.clap.fill")
                .font(.custom("Clap", size: 32))
                .padding(24)
            List {
                Section(header: Text("Lecture en cours")) {
                    TrackView(remote: remote)
                }
                Section(header: Text("Equipe")) {
                    Text(buzzerPool.lastBuzz == nil ? "" : buzzerPool.lastBuzz!.teamName)
                }
                Section(header: Text("Mauvaise réponse?")) {
                    Button("Pas de points") {
                        buzzerPool.clearLastBuzz(addPoints: 0)
                    }
                    .foregroundColor(.accentColor)
                }
                Section(header: Text("Bonne réponse?")) {
                    Button("+1 point") {
                        buzzerPool.clearLastBuzz(addPoints: 1)
                    }
                    .foregroundColor(.accentColor)
                    Button("+2 point") {
                        buzzerPool.clearLastBuzz(addPoints: 2)
                    }
                    .foregroundColor(.accentColor)
                    Button("+3 point") {
                        buzzerPool.clearLastBuzz(addPoints: 3)
                    }
                    .foregroundColor(.accentColor)
                    Button("+4 point") {
                        buzzerPool.clearLastBuzz(addPoints: 4)
                    }
                    .foregroundColor(.accentColor)
                    Button("+5 point") {
                        buzzerPool.clearLastBuzz(addPoints: 5)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .font(.headline)
        }
    }
}

struct AnswerView_Previews: PreviewProvider {
    static var previews: some View {
        AnswerView(buzzerPool: .constant(BuzzerPool.sampleData), remote: SpotifyRemote())
    }
}
