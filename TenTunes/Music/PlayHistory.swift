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
    
    var order: [Int] = []
    var shuffledOrder: [Int] = []
    
    var _playlistOrder: [Int] {
        return Array(0..<playlist.size)
    }
    var _shuffledPlaylistOrder: [Int] = []

    var playingIndex: Int? = nil
    
    var textFilter: String? = nil {
        didSet {
            if oldValue != textFilter {
                _filterChanged = true
            }
        }
    }
    
    var _filterChanged = false
    
    init(playlist: Playlist, shuffle: Bool = false) {
        self.playlist = playlist
        order = _playlistOrder
        reorder(shuffle: shuffle)
    }
    
    init(from: PlayHistory) {
        playlist = from.playlist
        textFilter = from.textFilter
        update(from: from)
    }
    
    var size: Int {
        return order.count
    }
    
    var rawPlayingIndex: Int? {
        return playingIndex != nil ? shuffledOrder[safe: playingIndex ?? -1] : nil
    }
    
    func update(from: PlayHistory) {
        guard playlist === from.playlist else {
            fatalError("Wrong playlist")
        }

        shuffledOrder = from.shuffledOrder
        order = from.order
        _shuffledPlaylistOrder = from._shuffledPlaylistOrder

        playingIndex = from.playingIndex
    }
    
    func reorder(shuffle: Bool) {
        let prev = rawPlayingIndex

        _shuffledPlaylistOrder = _playlistOrder

        if shuffle {
            _shuffledPlaylistOrder.shuffle()
            shuffledOrder = _shuffledPlaylistOrder
            
            if shuffledOrder.count != order.count { // We're filtered
                shuffledOrder = shuffledOrder.filter { order.contains($0) }
            }
        }
        else {
            shuffledOrder = order
        }

        move(to: prev, swap: shuffle)
    }
    
    func updated(completion: @escaping (PlayHistory) -> Swift.Void) {
        let copy = PlayHistory(from: self)
        
        DispatchQueue.global(qos: .userInitiated).async {
            copy._filter()

            DispatchQueue.main.async {
                completion(copy)
            }
        }
    }

    func _filter() {
        let prev = rawPlayingIndex

        order = _playlistOrder
        shuffledOrder = _shuffledPlaylistOrder

        guard let text = textFilter, text.count > 0 else {
            if let prev = prev {
                self.move(to: prev)
            }

            return
        }

        let terms = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        order = order.filter  { (index) -> Bool in
            return terms.filter({ (term) -> Bool in
                return self.playlist.tracks[index].searchable.filter({ (key) -> Bool in
                    return key.lowercased().contains(term.lowercased())
                }).first == nil
            }).first == nil
        }
        
        shuffledOrder = shuffledOrder.filter { order.contains($0) } // Don't do the heavy lifting twice
        
        self.move(to: prev)
    }
    
    func track(at: Int) -> Track? {
        return playlist.tracks[shuffledOrder[at]]
    }
    
    func viewed(at: Int) -> Track? {
        return playlist.tracks[safe: order[safe: at] ?? -1]
    }
    
    func move(to: Int?, swap: Bool = false) {
        guard let to = to else {
            self.playingIndex = nil
            return
        }
        
        if swap {
            if let to = shuffledOrder.index(of: to) {
                shuffledOrder.swapAt(to, 0)
                self.playingIndex = 0
            }
            else {
                self.playingIndex = 0 // Didn't find it,.. start anew
            }
        }
        else {
            self.playingIndex = to
        }
    }
    
    func move(_ by: Int) -> Track? {
        if size == 0 {
            self.playingIndex = nil
            return nil
        }

        if let playingIndex = self.playingIndex {
            self.playingIndex = playingIndex + by
        }
        else {
            self.playingIndex = by >= 0 ? 0 : size - 1
        }
        
        if self.playingIndex! >= size || self.playingIndex! < 0 {
            self.playingIndex = nil
            return nil
        }
        
        let track = self.track(at: self.playingIndex!)
        if track == nil {
            self.playingIndex = nil
        }
        return track
    }
}
