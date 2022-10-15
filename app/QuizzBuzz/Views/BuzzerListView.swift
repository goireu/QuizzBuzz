//
//  BuzzerListView.swift
//  bttest
//
//  Created by Greg DT on 23/03/2022.
//

import SwiftUI

struct BuzzerListView: View {
    @ObservedObject var viewModel: QuizzerViewModel

    var body: some View {
        List {
            ForEach($viewModel.buzzerPool.buzzers) { $buzzer in
                NavigationLink(destination: BuzzerEditView(buzzer: $buzzer)) {
                    VStack {
                        HStack {
                            //Spacer()
                            Image(systemName: buzzer.teamPlaying ? "checkmark.square.fill" : "x.square.fill")
                                .foregroundColor(buzzer.teamColor)
                            Spacer()
                            Text(buzzer.teamName)
                            Spacer()
                        }
                        HStack {
                            Label("\(buzzer.signal)", systemImage: "dot.radiowaves.left.and.right")
                                .font(.caption)
                            Spacer()
                            let handicapInMs = Int(viewModel.buzzerHandicapDelay(teamPointsInt: buzzer.teamPointsInt) * 1000)
                            Label("\(handicapInMs) ms", systemImage: "clock.fill")
                                .font(.caption)
                            Spacer()
                            Label("\(buzzer.buzzCount)", systemImage: "hands.clap.fill")
                                .font(.caption)
                            Spacer()
                            Label("\(buzzer.battery)", systemImage: "battery.100")
                                .font(.caption)
                        }
                        .padding(1)
                        Text(buzzer.id.uuidString)
                            .font(.caption2)
                            .padding(1)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Buzzers connus")
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { viewModel.buzzerPool.buzzers[$0].id }
        ids.forEach { viewModel.buzzerPool.removeBuzzer(buzzerID: $0) }
    }
}

struct BuzzerListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BuzzerListView(viewModel: QuizzerViewModel(buzzerPool: BuzzerPool.sampleData))
        }
    }
}
