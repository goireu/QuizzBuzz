//
//  AnswerView.swift
//  bttest
//
//  Created by Greg DT on 25/03/2022.
//

import SwiftUI

struct AnswerView: View {
    @ObservedObject var viewModel: QuizzerViewModel
    
    var body: some View {
        VStack {
            Label("Buzz!", systemImage: "hands.clap.fill")
                .font(.custom("Clap", size: 32))
                .padding(24)
            List {
                Section(header: Text("Lecture en cours")) {
                    TrackView(remote: viewModel.remote)
                }
                Section(header: Text("Equipe")) {
                    Text(viewModel.buzzerPool.lastBuzz == nil ? "" : viewModel.buzzerPool.lastBuzz!.teamName)
                }
            }
            .font(.headline)
            HStack {
                List {
                    Section(header: Text("Continuer")) {
                        Button("Incorrect") {
                            answer(false, nextTrack: false)
                        }
                        Button("+1 Point") {
                            answer(true, nextTrack: false, addPoints: 1)
                        }
                        Button("+2 Points") {
                            answer(true, nextTrack: false, addPoints: 2)
                        }
                        Button("+3 Points") {
                            answer(true, nextTrack: false, addPoints: 3)
                        }
                        Button("+4 Points") {
                            answer(true, nextTrack: false, addPoints: 4)
                        }
                        Button("+5 Points") {
                            answer(true, nextTrack: false, addPoints: 5)
                        }
                    }
                }
                .font(.headline)
                List {
                    Section(header: Text("Suivant")) {
                        Button("Incorrect") {
                            answer(false, nextTrack: true)
                        }
                        Button("+1 Point") {
                            answer(true, nextTrack: true, addPoints: 1)
                        }
                        Button("+2 Points") {
                            answer(true, nextTrack: true, addPoints: 2)
                        }
                        Button("+3 Points") {
                            answer(true, nextTrack: true, addPoints: 3)
                        }
                        Button("+4 Points") {
                            answer(true, nextTrack: true, addPoints: 4)
                        }
                        Button("+5 Points") {
                            answer(true, nextTrack: true, addPoints: 5)
                        }
                    }
                }
                .font(.headline)
            }
        }
    }
    
    private func answer(_ correct: Bool, nextTrack: Bool, addPoints: Int = 0) {
        if correct {
            viewModel.correctAnswer(addPoints: addPoints)
        } else {
            viewModel.wrongAnswer()
        }
        if nextTrack {
            viewModel.remote.next()
        }
    }
}

struct AnswerView_Previews: PreviewProvider {
    static var previews: some View {
        AnswerView(viewModel: QuizzerViewModel())
    }
}
