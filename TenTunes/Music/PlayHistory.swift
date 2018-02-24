//
//  PlayHistory.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlayHistory {
    var playlist: Playlist
    var order: [Int]? = nil
    var playingIndex: Int? = nil

    init(playlist: Playlist, shuffle: Bool) {
        self.playlist = playlist
        reorder(shuffle: shuffle)
    }
    
    func reorder(shuffle: Bool, keepCurrent: Bool = false) {
        let prev = playingIndex != nil ? trackIndex(playingIndex!) : nil
        
        if shuffle {
            order = Array(0..<playlist.size)
            order!.shuffle()
        }
        else {
            order = nil
        }
        
        if keepCurrent, let prev = prev {
            move(to: prev)
        }
        else {
            playingIndex = nil
        }
    }
    
    func trackIndex(_ at: Int) -> Int {
        return order?[at] ?? at
    }
    
    func track(at: Int) -> Track? {
        return playlist.tracks[trackIndex(at)]
    }
    
    func move(to: Int) {
        self.playingIndex = order?.index(of: to) ?? to
    }
    
    func move(_ by: Int) -> Track? {
        if playlist.size == 0 {
            self.playingIndex = nil
            return nil
        }

        if let playingIndex = self.playingIndex {
            self.playingIndex = playingIndex + by
        }
        else {
            self.playingIndex = by >= 0 ? 0 : playlist.size - 1
        }
        
        if self.playingIndex! >= playlist.size || self.playingIndex! < 0 {
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
