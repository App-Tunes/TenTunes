//
//  ViewController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation

let playString = "▶"
let pauseString = "||"

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
class ViewController: NSViewController {

    @IBOutlet var _tableView: NSTableView!
    @IBOutlet var _title: NSTextField!
    @IBOutlet var _subtitle: NSTextField!
    
    @IBOutlet var _play: NSButton!
    @IBOutlet var _stop: NSButton!

    var database: [Track]! = []
    
    var player: AVAudioPlayer?
    var playing: Track?

    override func viewDidLoad() {
        super.viewDidLoad()

        let path = "/Volumes/Lukebox/iTunes/iTunes Library.xml"
        
        if !FileManager.default.fileExists(atPath: path) {
            print("FILE UNAVAILABLE")
            exit(1)
        }

        let nsdict = NSDictionary(contentsOfFile: path)!
        let tracksRaw = nsdict.object(forKey: "Tracks") as! NSDictionary
        
        for (_, trackData) in tracksRaw {
            let trackData = trackData as! NSDictionary
            
            let title = trackData["Name"] as? String
            let author = trackData["Artist"] as? String
            let album = trackData["Album"] as? String
            let file = trackData["Location"] as? String

            self.database.append(Track(title: title, author: author, album: album, path: file))
        }
        
        self.updatePlaying()
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    func isPaused() -> Bool {
        return !(self.player?.isPlaying ?? false)
    }

    func updatePlaying() {
        guard let track = self.playing else {
            self.player = nil

            self._play.stringValue = playString
            
            self._title.stringValue = ""
            self._subtitle.stringValue = ""
            
            return
        }
        
        self._play.title = self.isPaused() ? playString : pauseString
        
        self._title.stringValue = track.rTitle()
        self._subtitle.stringValue = "\(track.rAuthor()) - \(track.rAlbum())"
    }
    
    func play(track: Track?) -> Void {
        if let player = self.player {
            player.stop()
        }
        
        if let track = track {
            do {
                let player = try AVAudioPlayer(contentsOf: URL(string: track.path!)!)
                self.player = player
                
                player.prepareToPlay()
                player.play()
                self.playing = track
            } catch let error {
                print(error.localizedDescription)
                self.player = nil
                self.playing = nil
            }
        }
        else {
            self.player = nil
            self.playing = nil
        }
        
        self.updatePlaying()
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = self._tableView.clickedRow
        let track = self.database[row]
        
        if track.path != nil {
            self.play(track: track)
        }
    }
    
    @IBAction func play(_ sender: Any) {
        if self.playing != nil {
            if self.isPaused() {
                self.player!.play()
            }
            else {
                self.player!.pause()
            }
        }
        else {
            let selectedRow = self._tableView.selectedRow
            self.play(track: self.database[selectedRow])
        }
        
        self.updatePlaying()
    }
    
    @IBAction func stop(_ sender: Any) {
        self.play(track: nil)
    }
    
    func keyDown(theEvent: NSEvent) {
        if let keyString = theEvent.charactersIgnoringModifiers, keyString == " " {
            self._play.performClick(self)
        }
    }
}

extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        static let DateCell = NSUserInterfaceItemIdentifier(rawValue: "dateCell")
        static let SizeCell = NSUserInterfaceItemIdentifier(rawValue: "sizeCell")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        // 1
        let track = self.database[row]
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            if let cell = tableView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? NSTableCellView {
                let artist = track.rAuthor()
                let title = track.rTitle()
                let album = track.rAlbum()

                cell.textField?.stringValue = "\(artist) - \(title) (\(album))"
                return cell
            }
        } else if tableColumn == tableView.tableColumns[1] {
            
        } else if tableColumn == tableView.tableColumns[2] {
            
        }
        
        return nil
    }
}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return database.count;
    }
}
