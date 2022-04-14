//
//  SpotifyRemote.swift
//  QuizzBuzz
//
//  Created by Greg DT on 27/03/2022.
//

import Foundation
import Combine

struct SpotifyRemoteConfig {
    var seekToRandom = false
    // Not really config below but very handy to have them there
    var canSeek = false
    var canSkip = false
}

class SpotifyRemote : NSObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, ObservableObject {
    
    static private let kAccessTokenKey = "access-token-key"
    private let redirectUri = URL(string:"spotify-ios-quick-start://spotify-login-callback")!
    private let clientIdentifier = "7b51560679a341769c187ea9f97e8b20"
    private var authToken: String? = nil
    
    lazy var appRemote: SPTAppRemote = {
        let configuration = SPTConfiguration(clientID: self.clientIdentifier, redirectURL: self.redirectUri)
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    public var playingSubject: PassthroughSubject<Bool, Never> = .init()
    
    @Published public var hasError = false
    @Published public var errorMessage = ""
    func showError(_ context: String, error: Error? = nil) {
        errorMessage = "\(context): \(error?.localizedDescription ?? "<Erreur inconnue>")"
        hasError = true
    }
    
    @Published var trackTitle = "<Titre>"
    @Published var trackAlbum = "<Album>"
    @Published var trackArtist = "<Artiste>"
    @Published var isPaused = true
    @Published var isConnected = false

    @Published var config = SpotifyRemoteConfig()
    
    // MARK: - Establish connection
    private var skipUponConnect = false
    func authorize(andSkip: Bool) {
        skipUponConnect = andSkip
        if appRemote.authorizeAndPlayURI("") == false {
            showError("Echec d'ouverture de Spotify")
        }
    }
    func connect(from url: URL) {
        let parameters = appRemote.authorizationParameters(from: url)
        
        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            authToken = accessToken
            appRemote.connectionParameters.accessToken = accessToken
            appRemote.connect()
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            showError("Connexion à Spotify impossible", error: errorDescription)
            print(errorDescription)
        }
        
    }
    
    // MARK: - control music
    func pauseResume() {
        if appRemote.isConnected {
            if isPaused {
                appRemote.playerAPI?.resume(defaultCallback)
            } else {
                appRemote.playerAPI?.pause(defaultCallback)
            }
        }
        else {
            authorize(andSkip: false)
        }
    }
    func pause() {
        if appRemote.isConnected && !isPaused {
            appRemote.playerAPI?.pause(defaultCallback)
        }
    }
    func next() {
        guard config.canSkip else { return }
        if appRemote.isConnected {
            appRemote.playerAPI?.skip(toNext: defaultCallback)
        }
        else {
            authorize(andSkip: true)
        }
    }
    
    // MARK: - Handle events
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        // If requested, skip immediatly after connecting
        if skipUponConnect && config.canSkip {
            print("SKIP UPON CONNECT")
            appRemote.playerAPI?.skip(toNext: defaultCallback)
            skipUponConnect = false
        }
        appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
        print("REMOTE CONNECTED")
        isConnected = true
    }
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("REMOTE DISCONNECTED")
        isConnected = false
    }
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("REMOTE CONNECTION FAIL: \(error?.localizedDescription ?? "<unknown>")")
        showError("Echec de connexion à Spotify", error: error)
    }
    
    private var previousTrackUri = ""
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        // Collect status
        isPaused = playerState.isPaused
        config.canSkip = playerState.playbackRestrictions.canSkipNext
        config.canSeek = playerState.playbackRestrictions.canSeek
        // Collect Track data
        trackAlbum = playerState.track.album.name
        trackArtist = playerState.track.artist.name
        trackTitle = playerState.track.name
        // Do what we need to do upon changing track
        if previousTrackUri != playerState.track.uri {
            // Seek to a random location if we changed song and mode is enabled (and Spotify allows it)
            if config.seekToRandom && config.canSeek {
                print("SKIPPING TO RANDOM LOCATION")
                let seekPos = Int(Double(playerState.track.duration) * Double.random(in: 0.3...0.7))
                appRemote.playerAPI?.seek(toPosition: seekPos, callback: defaultCallback)
            }
            previousTrackUri = playerState.track.uri
        }
        print("REMOTE PLAYER STATE CHANGED")
        // Notify view model
        playingSubject.send(!playerState.isPaused)
    }
    
    var defaultCallback: SPTAppRemoteCallback {
        get {
            return {[weak self] _, error in
                if let error = error {
                    print("Spotify callback error: \(error.localizedDescription)")
                    self?.showError("Erreur de contrôle de Spotify", error: error)
                }
            }
        }
    }
}
