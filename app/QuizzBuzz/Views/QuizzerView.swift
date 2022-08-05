//
//  QuizzerView.swift
//  bttest
//
//  Created by Greg DT on 25/03/2022.
//

import SwiftUI
import AVFoundation

struct QuizzerView: View {
    @StateObject var viewModel = QuizzerViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Télécommande")) {
                TrackView(remote: viewModel.remote)
                RemoteView(remote: viewModel.remote)
            }
            Section(header: Text("Equipes en jeu")) {
                ForEach(viewModel.buzzerPool.playingBuzzers) { buzzer in
                    HStack {
                        Text(buzzer.teamPoints)
                        Image(systemName: buzzer.hasBuzzed ? "hands.clap" : "hands.clap.fill")
                            .foregroundColor(buzzer.teamColor)
                        Text(buzzer.teamName)
                            .foregroundColor(buzzer.isConnected ? .black : .gray)
                        Spacer()
                        Image(systemName: buzzer.isConnected ? "wifi" : "wifi.exclamationmark")
                    }
                }
                if !viewModel.buzzerPool.allowMultipleBuzz {
                    HStack {
                        Spacer()
                        Button("Remettre les équipes en jeu") {
                            viewModel.resetBuzzs()
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        Spacer()
                    }
                    .disabled(viewModel.buzzerPool.buzzCount == 0)
                }
              }
            Section(header: Text("Configuration")) {
                NavigationLink(destination: BuzzerListView(viewModel: viewModel)) {
                    HStack {
                        Spacer()
                        Text("Configuration des buzzers")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                }
                NavigationLink(destination: ConfigEditView(viewModel: viewModel)) {
                    HStack {
                        Spacer()
                        Text("Configuration du jeu")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.buzzerPool.buzzPending) {
            AnswerView(viewModel: viewModel)
                .onAppear() {
                    viewModel.remote.pause()
                    viewModel.lastBuzzerLedBlink(blinkCount: 30)
                    AssetSounds.instance.play(name: viewModel.buzzerPool.lastBuzz?.teamSound ?? "")
                }
        }
        .sheet(isPresented: $viewModel.remote.hasError) {
            VStack {
                Text("Erreur")
                    .font(.custom("_custom_", size: 36))
                Text("")
                Text(viewModel.remote.errorMessage)
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onOpenURL { url in
            viewModel.remote.connect(from: url)
        }
    }
}

struct QuizzerView_Previews: PreviewProvider {
    static var previews: some View {
        QuizzerView()
    }
}
