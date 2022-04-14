//
//  ConfigView.swift
//  QuizzBuzz
//
//  Created by Greg DT on 27/03/2022.
//

import SwiftUI

struct ConfigEditView: View {
    @Binding var buzzerPool: BuzzerPool
    @Binding var remoteConfig: SpotifyRemoteConfig
    
    var body: some View {
        Form {
            Section(footer: Text("Si cette option est activée, chaque équipe peut buzzer plusieurs fois par chanson.")) {
                Toggle("Buzz multiples autorisés", isOn: $buzzerPool.allowMultipleBuzz)
            }
            Section(footer: Text("Si cette option est activée, les chansons démarrent aléatoirement au milieu du morceau. Cette option n'est accessible qu'une fois Spotify connecté.")) {
                Toggle("Début de piste aléatoire", isOn: $remoteConfig.seekToRandom)
                    .disabled(!remoteConfig.canSeek)
            }
            Section(footer: Text("Remet tous les joueurs en jeu et les scores à zéro.")) {
                HStack {
                    Spacer()
                    Button("Réinitialiser le jeu") {
                        buzzerPool.resetBuzzs(clearScores: true)
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }
}

struct ConfigEditView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigEditView(buzzerPool: .constant(BuzzerPool.sampleData), remoteConfig: .constant(SpotifyRemoteConfig()))
    }
}
