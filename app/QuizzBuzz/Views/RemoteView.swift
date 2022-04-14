//
//  RemoteView.swift
//  QuizzBuzz
//
//  Created by Greg DT on 29/03/2022.
//

import SwiftUI

struct RemoteView: View {
    @ObservedObject var viewModel: QuizzerViewModel
    @ObservedObject var remote: SpotifyRemote
    
    var body: some View {
        HStack {
            Spacer()
            Button() {
                remote.pauseResume()
                print("Play")
            } label: {
                Image(systemName: remote.isPaused ? "play.fill" : "pause.fill")
                    .resizable().frame(width: 24, height: 24)
            }
            .foregroundColor(.accentColor)
            .buttonStyle(BorderlessButtonStyle())
            Spacer()
            Button() {
                remote.next()
                print("Next")
                viewModel.buzzerPool.resetBuzzs()
            } label: {
                Image(systemName: "forward.end.alt.fill")
                    .resizable().frame(width: 24, height: 24)
            }
            .foregroundColor(.accentColor)
            .buttonStyle(BorderlessButtonStyle())
            .disabled(!remote.config.canSkip)
            Spacer()
        }
    }
}

struct RemoteView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteView(viewModel: QuizzerViewModel(), remote: SpotifyRemote())
    }
}
