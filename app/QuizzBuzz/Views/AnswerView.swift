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
                Section(header: Text("Mauvaise réponse?")) {
                    Button("Pas de points") {
                        answer(false)
                    }
                    .foregroundColor(.accentColor)
                }
                Section(header: Text("Bonne réponse?")) {
                    Button("+1 point") {
                        answer(true, addPoints: 1)
                    }
                    .foregroundColor(.accentColor)
                    Button("+2 point") {
                        answer(true, addPoints: 2)
                    }
                    .foregroundColor(.accentColor)
                    Button("+3 point") {
                        answer(true, addPoints: 3)
                    }
                    .foregroundColor(.accentColor)
                    Button("+4 point") {
                        answer(true, addPoints: 4)
                    }
                    .foregroundColor(.accentColor)
                    Button("+5 point") {
                        answer(true, addPoints: 5)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .font(.headline)
        }
    }
    
    private func answer(_ correct: Bool, addPoints: Int = 0) {
        if correct {
            viewModel.correctAnswer(addPoints: addPoints)
        } else {
            viewModel.wrongAnswer()
        }
    }
}

struct AnswerView_Previews: PreviewProvider {
    static var previews: some View {
        AnswerView(viewModel: QuizzerViewModel())
    }
}
