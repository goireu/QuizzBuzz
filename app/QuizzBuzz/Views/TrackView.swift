//
//  TrackView.swift
//  QuizzBuzz
//
//  Created by Greg DT on 29/03/2022.
//

import SwiftUI

struct TrackView: View {
    @ObservedObject var remote: SpotifyRemote

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text(remote.trackTitle)
                Text(remote.trackAlbum)
                    .font(.caption)
                Text(remote.trackArtist)
            }
            .foregroundColor(remote.isConnected ? .black : .gray)
            Spacer()
        }
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        TrackView(remote: SpotifyRemote())
    }
}
