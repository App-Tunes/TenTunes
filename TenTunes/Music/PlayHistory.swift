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
    var shuffledOrder: [Int]? = nil
    
    var _playlistOrder: [Int] = []
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
        _playlistOrder = Array(0..<playlist.size)
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
    
    func playing(at: Int) -> Int? {
        return (shuffledOrder ?? order)[safe: at]
    }
    
    var rawPlayingIndex: Int? {
        return playingIndex != nil ? playing(at: playingIndex ?? -1) : nil
    }
    
    func update(from: PlayHistory) {
        guard playlist === from.playlist else {
            fatalError("Wrong playlist")
        }

        _playlistOrder = from._playlistOrder
        order = from.order
        shuffledOrder = from.shuffledOrder
        _shuffledPlaylistOrder = from._shuffledPlaylistOrder

        playingIndex = from.playingIndex
    }
    
    func reorder(shuffle: Bool) {
        let prev = rawPlayingIndex

        _shuffledPlaylistOrder = _playlistOrder

        if shuffle {
            _shuffledPlaylistOrder.shuffle()
          
            shuffledOrder = _shuffledPlaylistOrder
            if shuffledOrder!.count != playlist.size { // We're filtered
                shuffledOrder = shuffledOrder!.filter { order.contains($0) }
            }
        }
        else {
            shuffledOrder = nil
        }

        move(to: prev)
    }
    
    func reorder(sort: ((Track, Track) -> Bool)?) {
        let prev = rawPlayingIndex
        
        // Always start from scratch since we can't do sub-sorts easily anyway
        _playlistOrder = Array(0..<playlist.size)
        
        if let sort = sort {
            _playlistOrder = _playlistOrder.sorted { sort(playlist.track(at: $0)!, playlist.track(at: $1)!) }
        }
        
        if order.count != playlist.size { // We're filtered
            order = _playlistOrder.filter { order.contains($0) }
        }
        else {
            order = _playlistOrder
        }

        if shuffledOrder == nil { // We've resorted the playing list
            move(to: prev)
        }
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
        
        if let shuffledOrder = shuffledOrder {
            self.shuffledOrder = shuffledOrder.filter { order.contains($0) } // Don't do the heavy lifting twice
        }
        
        self.move(to: prev)
    }
    
    func track(at: Int) -> Track? {
        return playlist.tracks[playing(at: at)!]
    }
    
    func viewed(at: Int) -> Track? {
        return playlist.tracks[safe: order[safe: at] ?? -1]
    }
    
    func move(to: Int?) {
        guard let to = to else {
            self.playingIndex = nil
            return
        }
        
        if let shuffledOrder = shuffledOrder {
            if let to = shuffledOrder.index(of: to) {
                self.shuffledOrder!.swapAt(to, 0)
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
