//
//  ConfigView.swift
//  QuizzBuzz
//
//  Created by Greg DT on 27/03/2022.
//

import SwiftUI

struct ConfigEditView: View {
    @ObservedObject var viewModel: QuizzerViewModel
    
    var body: some View {
        Form {
            Section(footer: Text("Si cette option est activée, chaque équipe peut buzzer plusieurs fois par chanson.")) {
                Toggle("Buzz multiples autorisés", isOn: $viewModel.buzzerPool.allowMultipleBuzz)
            }
            Section(footer: Text("Si cette option est activée, les chansons démarrent aléatoirement au milieu du morceau. Cette option n'est accessible qu'une fois Spotify connecté.")) {
                Toggle("Début de piste aléatoire", isOn: $viewModel.remote.config.seekToRandom)
                    .disabled(!viewModel.remote.config.canSeek)
            }
            Section(footer: Text("Pour chaque point d'écart avec le score le plus bas, le buzzer sera désactivé en début de chanson de ce délai.")) {
                HStack {
                    Text("Handicap:")
                    Slider(value: $viewModel.buzzerPool.handicapInMs, in: 0...1000, step: 100)
                    Text("\(Int(viewModel.buzzerPool.handicapInMs)) ms")
                }
            }
            Section(footer: Text("Remet tous les joueurs en jeu et les scores à zéro.")) {
                HStack {
                    Spacer()
                    Button("Réinitialiser le jeu") {
                        viewModel.resetBuzzs(clearScores: true)
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
        ConfigEditView(viewModel: QuizzerViewModel())
    }
}
