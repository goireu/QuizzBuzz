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
    @ObservedObject var remote: SpotifyRemote
    
    var body: some View {
        List {
            Section(header: Text("Télécommande")) {
                TrackView(remote: remote)
                RemoteView(viewModel: viewModel, remote: remote)
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
                NavigationLink(destination: BuzzerListView(buzzerPool: $viewModel.buzzerPool)) {
                    HStack {
                        Spacer()
                        Text("Configuration des buzzers")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                }
                NavigationLink(destination: ConfigEditView(viewModel: viewModel, remoteConfig: $remote.config)) {
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
            AnswerView(viewModel: viewModel, remote: remote)
                .onAppear() {
                    remote.pause()
                    viewModel.lastBuzzerLedBlink(blinkCount: 30)
                    AssetSounds.instance.play(name: viewModel.buzzerPool.lastBuzz?.teamSound ?? "")
                }
        }
        .sheet(isPresented: $remote.hasError) {
            VStack {
                Text("Erreur")
                    .font(.custom("_custom_", size: 36))
                Text("")
                Text(remote.errorMessage)
            }
        }
        .onAppear {
            viewModel.start(playingSubject: remote.playingSubject)
        }
    }
}

struct QuizzerView_Previews: PreviewProvider {
    static var previews: some View {
        QuizzerView(remote: SpotifyRemote())
    }
}
