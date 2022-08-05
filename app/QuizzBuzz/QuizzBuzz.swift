//
//  bttestApp.swift
//  bttest
//
//  Created by Greg DT on 14/03/2022.
//

import SwiftUI

class MyData : ObservableObject {
    @Published var str = "toto"
}

@main
struct QuizzBuzz: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                QuizzerView()
                    .navigationBarHidden(true)
            }
        }
    }
}
