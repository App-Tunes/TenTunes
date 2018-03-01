//
//  PlayHistory.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlayHistory {
    let playlist: Playlist

    var order: [Track]
    var shuffled: [Track]?
    var playingIndex: Int = 0
    
    init(playlist: Playlist) {
        self.playlist = playlist
        self.order = playlist.tracks
    }
    
    init(from: PlayHistory) {
        playlist = from.playlist
        
        order = from.order
        playingIndex = from.playingIndex
    }
    
    var isUntouched: Bool {
        return order == playlist.tracks
    }
    
    var isUnsorted: Bool {
        return order.sharesOrder(with: playlist.tracks)
    }
    
    // Order, Filter
    
    func filter(by filter: @escaping (Track) -> Bool) {
        var m = 0
        
        let filter: ([Track]) -> [Track] = { list in
            list.enumerated().filter ({ tuple in
                let (idx, track) = tuple // Required in Swift 4 Beta? Yeah.
                let remove = filter(track)
                m += remove && idx < self.playingIndex ? 1 : 0
                return remove
            }).map { $0.element }
        }
        
        order = filter(order)
        shuffled = shuffled ?=> filter // Filter shuffle too if we need it
        
        playingIndex -= m
    }
    
    static func filter(findText text: String?) -> ((Track) -> Bool)? {
        guard let text = text, text.count > 0 else {
            return nil
        }
        
        let terms = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return { (track) in
            return terms.allMatch { (term) -> Bool in
                return track.searchable.anyMatch { (key) -> Bool in
                    return key.lowercased().contains(term.lowercased())
                }
            }
        }
    }
    
    func sort(by sort: (Track, Track) -> Bool) {
        let playing = order[safe: playingIndex]
        
        order = order.sorted(by: sort)
        
        if shuffled == nil, let playing = playing {
            playingIndex = order.index(of: playing)!
        }
    }
    
    func unshuffle() {
        let playing = playingTrack
        shuffled = nil
        if let playing = playing {
            playingIndex = order.index(of: playing)!
        }
        // Else we were at start or end
    }
    
    func shuffle() {
        let playing = playingTrack
        
        shuffled = order
        shuffled!.shuffle()
        
        if let playing = playing {
            let idx = shuffled!.index(of: playing)!
            shuffled?.swapAt(0, idx)
            playingIndex = 0
        }
    }

    // Query
    
    var size: Int { return order.count }
    
    func track(at: Int) -> Track? {
        return (shuffled ?? order)[safe: at]
    }
    
    func indexOf(track: Track) -> Int? {
        return (shuffled ?? order).index(of: track)
    }
    
    func move(to: Int) {
        playingIndex = (-1...order.count).clamp(to)
    }
    
    func move(by: Int) -> Track? {
        move(to: playingIndex + by)
        return track(at: playingIndex)
    }
    
    var playingTrack: Track? { return track(at: playingIndex) }
}
