//
//  ViewController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

var database = [
    [
        "artist": "Air",
        "title": "Caramel Prisoner",
        "album": "10,000 Hz Legend",
    ],
    [
        "artist": "Air",
        "title": "Don't Be Light",
        "album": "10,000 Hz Legend",
        ],
    [
        "artist": "Boris Blank",
        "title": "Midnight Procession",
        "album": "Electrified",
        ],

]

class ViewController: NSViewController {

    @IBOutlet var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
        let item = database[row]
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            if let cell = tableView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? NSTableCellView {
                let artist = item["artist"]!
                let title = item["title"]!
                let album = item["album"]!

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
