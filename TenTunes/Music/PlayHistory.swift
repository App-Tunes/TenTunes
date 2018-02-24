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
    
    var order: [Int] = []
    var viewOrder: [Int] = []
    var shuffledOrder: [Int] = []

    var playingIndex: Int? = nil
    
    var textFilter: String? = nil {
        didSet {
            filter(textFilter)
        }
    }

    init(playlist: Playlist, shuffle: Bool = false) {
        self.playlist = playlist
        reorder(shuffle: shuffle)
    }
    
    var size: Int {
        return order.count
    }
    
    func reorder(shuffle: Bool, keepCurrent: Bool = false) {
        let prev = playingIndex != nil ? order[playingIndex!] : nil
        
        viewOrder = Array(0..<playlist.size)
        shuffledOrder = viewOrder

        if shuffle {
            shuffledOrder.shuffle()
        }

        order = shuffledOrder

        if keepCurrent, let prev = prev {
            move(to: prev, swap: shuffle)
        }
        else {
            playingIndex = nil
        }
        
        filter(textFilter)
    }
    
    func filter(_ text: String?) {
        viewOrder = Array(0..<playlist.size)
        order = shuffledOrder
        
        guard let text = text, text.count > 0 else {
            return
        }

        let prev = playingIndex != nil ? order[playingIndex!] : nil
        let terms = text.components(separatedBy: .whitespacesAndNewlines)
        
        let filter: (Int) -> Bool = { (index) -> Bool in
            return terms.filter({ (term) -> Bool in
                return self.playlist.tracks[index].searchable.filter({ (key) -> Bool in
                    return key.lowercased().contains(term.lowercased())
                }).first == nil
            }).first == nil
        }
        
        order = order.filter(filter)
        viewOrder = viewOrder.filter(filter)

        if let prev = prev {
            move(to: prev)
        }
    }
    
    func track(at: Int) -> Track? {
        return playlist.tracks[order[at]]
    }
    
    func viewed(at: Int) -> Track? {
        return playlist.tracks[safe: viewOrder[safe: at] ?? -1]
    }
    
    func move(to: Int, swap: Bool = false) {
        if swap {
            if let to = order.index(of: to) {
                order.swapAt(to, 0)
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
