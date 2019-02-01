//
//  Cocoa+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 09.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSImage {
    func tinted(in tint: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else { return self }
        tinted.lockFocus()
        tint.set()
        
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        __NSRectFillUsingOperation(imageRect, .sourceAtop)
        
        tinted.unlockFocus()
        return tinted
    }
    
    func resized(w: CGFloat, h: CGFloat) -> NSImage {
        let destSize = NSMakeSize(w, h)
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    
    func blurred(radius: Double) -> NSImage {
        let imageToBlur = CIImage(data: tiffRepresentation!)
        let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur")
        gaussianBlurFilter?.setValue(imageToBlur, forKey: kCIInputImageKey)
        gaussianBlurFilter?.setValue(NSNumber(floatLiteral: radius), forKey: "inputRadius")
        
        let rep = gaussianBlurFilter?.value(forKey: kCIOutputImageKey) as! CIImage
        let cgImage =  CIContext().createCGImage(rep, from: imageToBlur!.extent)!
        
        return NSImage(cgImage: cgImage, size: size)
    }
    
    var bitmapRepresentation : NSBitmapImageRep? {
        if let bitmap = representations.of(type: NSBitmapImageRep.self).first {
            return bitmap
        }
        
        return tiffRepresentation ?=> NSBitmapImageRep.init
    }
    
    var jpgRepresentation : Data? {
        // Try direct conversion first
        if let jpg = representations.of(type: NSBitmapImageRep.self).compactMap({ $0.representation(using: .jpeg, properties: [:]) }).first {
            return jpg
        }
        
        // Else, convert to tiff first, almost any rep supports that
        guard let tiffData = tiffRepresentation else {
            return nil // Eh
        }
        let imageRep = NSBitmapImageRep(data: tiffData)
        return imageRep?.representation(using: .jpeg, properties: [:])
    }
}

extension NSTextField {
    func setStringColor(_ color: NSColor) {
        attributedStringValue = attributedStringValue.with(color, for: .foregroundColor)
    }
    
    func setAlignment(_ alignment: NSTextAlignment) {
        attributedStringValue = attributedStringValue.with(alignment: alignment)
    }
}

extension NSButton {
    func set(text: String) {
        self.attributedTitle = NSAttributedString(string: text, attributes: self.attributedTitle.attributes(at: 0, effectiveRange: nil))
    }
    
    func set(color: NSColor) {
        attributedTitle = attributedTitle.with(color, for: .foregroundColor)
    }
}

extension NSTableView {
    var clickedRows: [Int] {
        if isRowSelected(clickedRow) {
            return Array(selectedRowIndexes)
        }
        return [clickedRow]
    }
    
    func animateDifference<Element : Equatable>(from: [Element]?, to: [Element]?) {
        if let from = from, let to = to, let (left, right) = from.difference(from: to) {
            if (left ?? right!).count > 100 {
                // Give up, this will look shite anyhow
                reloadData()
            }
            else if let removed = left {
                removeRows(at: IndexSet(removed), withAnimation: .slideDown)
            }
            else if let added = right {
                insertRows(at: IndexSet(added), withAnimation: .slideUp)
            }
        }
        else if let from = from, let to = to, let movement = from.movement(to: to) {
            for (src, dst) in movement {
                moveRow(at: src, to: dst)
            }
        }
        else {
            reloadData()
        }
    }
    
    func tableColumn(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> NSTableColumn? {
        return tableColumns[safe: column(withIdentifier: identifier)]
    }
    
    func scrollRowToTop(_ row: Int) {
        scroll(NSPoint(x: 0, y: CGFloat(row) * (rowHeight + intercellSpacing.height)))
    }
}

extension NSMenu {
    func item(withAction: Selector) -> NSMenuItem? {
        return items.filter { $0.action == withAction }.first
    }
    
    func item(withRepresentedObject represented: Any?) -> NSMenuItem? {
        return items[safe: indexOfItem(withRepresentedObject: represented)]
    }
    
    func resizeImages(max: CGFloat = 15) {
        for item in items {
            item.resizeImage(max: max)
        }
    }
}

extension NSMenuItem {
    var isVisible: Bool {
        get { return !isHidden }
        set(visible) { isHidden = !visible }
    }
    
    func resizeImage(max: CGFloat = 15) {
        guard let image = self.image else {
            return
        }
        
        if image.size.width > image.size.height {
            self.image = image.resized(w: max, h: image.size.height * max / image.size.width)
        }
        else {
            self.image = image.resized(w: image.size.width * max / image.size.height, h: max)
        }
    }
}

extension NSWindow {
    func positionNextTo(view: NSView) {
        let windowPoint = view.convert(NSPoint(x: view.bounds.width, y: view.bounds.height / 2), to: nil)
        let screenPoint = view.window!.convertToScreen(NSRect(origin: windowPoint, size: .zero)).origin

        let size = self.frame.size
        var frame = NSRect(x: screenPoint.x, y: screenPoint.y - size.height / 2, width: size.width, height: size.height)

        let limit = view.window!.screen!.visibleFrame
        if frame.maxX > limit.maxX {
            frame.origin.x = limit.maxX - frame.size.width
        }
        
        setFrame(frame, display: true)
    }
    
    func moveStandardButtons(x: CGFloat, y: CGFloat) {
        let windowButtonsView = standardWindowButton(.closeButton)!.superview!
        windowButtonsView.frame = windowButtonsView.frame.offsetBy(dx: x, dy: -y)
        
        let topBarView = windowButtonsView.superview!
        topBarView.frame = NSRect(x: topBarView.frame.minX, y: topBarView.frame.minY - y, width: topBarView.frame.width, height: topBarView.frame.height + y)
    }
    
    var isMouseInside: Bool {
        return NSWindow.windowNumber(at: NSEvent.mouseLocation, belowWindowWithWindowNumber: 0) == windowNumber
    }
}

extension NSOutlineView {
    func edit(row: Int, with event: NSEvent?, select: Bool) {
        editColumn(0, row: row, with: event, select: select)
    }
    
    func animateDifference<Element : Equatable>(childrenOf parent: Any?, from: [Element]?, to: [Element]?) {
        let fromCount = from?.count ?? 0
        let toCount = to?.count ?? 0
        
        guard abs(fromCount - toCount) < 100 else {
            // Give up, this will look shite anyhow
            reloadItem(parent, reloadChildren: true)
            return
        }
        
        if let from = from, let to = to, let (left, right) = from.difference(from: to) {
            guard (left ?? right!).count < 100 else {
                // Give up, this will look shite anyhow
                reloadItem(parent, reloadChildren: true)
                return
            }
            
            if let removed = left {
                removeItems(at: IndexSet(removed), inParent: parent, withAnimation: .slideDown)
            }
            else if let added = right {
                insertItems(at: IndexSet(added), inParent: parent, withAnimation: .slideUp)
            }
        }
        else {
            // Animate size difference first
            if fromCount > toCount {
                removeItems(at: IndexSet(integersIn: toCount ..< fromCount), inParent: parent, withAnimation: .slideDown)
            }
            else if toCount > fromCount {
                insertItems(at: IndexSet(integersIn: fromCount ..< toCount), inParent: parent, withAnimation: .slideUp)
            }
            
            reloadItems(at: IndexSet(integersIn: 0 ..< min(fromCount, toCount)), inParent: parent)
        }
    }

    func reloadItems(at rows: IndexSet, inParent parent: Any?) {
        removeItems(at: rows, inParent: parent, withAnimation: [])
        insertItems(at: rows, inParent: parent, withAnimation: [])
    }

    func animateDelete(items: [Any]) {
        guard items.count < 100 else {
            reloadData()
            return
        }
        
        for element in items {
            let idx = childIndex(forItem: element)
            if idx >= 0 {
                removeItems(at: IndexSet(integer: idx), inParent: parent(forItem: element), withAnimation: .slideDown)
            }
        }
    }
    
    func animateInsert<T>(items: [T], position: (T) -> (Int, T?)?) {
        guard items.count < 100 else {
            reloadData()
            return
        }
        
        for t in items {
            if let (pos, parent) = position(t) {
                insertItems(at: IndexSet(integer: pos), inParent: parent, withAnimation: .slideUp)
            }
        }
    }
    
    func reloadItems<C : Collection, E>(_ items: C, reloadChildren: Bool = false) where C.Element == E? {
        if items.contains(where: { $0 == nil }) {
            reloadData()
            return
        }
        
        for case let item as AnyObject in items {
            let parent = self.parent(forItem: item)
            let idx = childIndex(forItem: item)
            guard (dataSource?.outlineView?(self, numberOfChildrenOfItem: parent) ?? 0) > idx else {
                // We have been deleted or something, but the parent will be reloaded anyway
                continue
            }
            
            reloadItem(item, reloadChildren: reloadChildren)
        }
    }
    
    func children(ofItem item: Any?) -> [Any] {
        let number = numberOfChildren(ofItem: item)
        return (0..<number).map {
            self.child($0, ofItem: item)!
        }
    }
    
    func view(atColumn column: Int, forItem item: Any?, makeIfNecessary: Bool) -> NSView? {
        let itemRow = row(forItem: item)
        return itemRow >= 0 ? view(atColumn: column, row: itemRow, makeIfNecessary: makeIfNecessary) : nil
    }
    
    @discardableResult
    func toggleItemExpanded(_ item: Any?) -> Bool {
        guard isItemExpanded(item) else {
            (animator() as NSOutlineView).expandItem(item)
            return true
        }

        (animator() as NSOutlineView).collapseItem(item)
        return false
    }
}

extension FileManager {
    func regularFiles(inDirectory directory: URL) -> [URL] {
        let enumerator = FileManager.default.enumerator(at: directory,
                                                        includingPropertiesForKeys: [ .isRegularFileKey ],
                                                        options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        var allFiles: [URL] = []
        
        for case let url as URL in enumerator {
            let isRegularFile = try? url.resourceValues(forKeys: [ .isRegularFileKey ]).isRegularFile!
            if isRegularFile ?? false {
                allFiles.append(url)
            }
        }
        
        return allFiles
    }
    
    func sizeOfItem(at url: URL) throws -> UInt64 {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.size] as! UInt64
    }
}

extension NSView {
    @IBInspectable
    var _alphaValue: CGFloat {
        set { alphaValue = newValue }
        get { return alphaValue }
    }
    
    func removeSubview(_ remove: NSView?, andAdd add: NSView?, order: NSWindow.OrderingMode? = nil) {
        if let remove = remove, let add = add {
            replaceSubview(remove, with: add)
        }
        else if let remove = remove {
            subviews.remove(element: remove)
        }
        else if let add = add {
            if let order = order {
                addSubview(add, positioned: order, relativeTo: nil)
            }
            else {
                addSubview(add)
            }
        }
    }
    
    func setFullSizeContent(_ view: NSView?) {
        subviews = []
        
        guard let view = view else {
            return
        }
        
        view.frame = bounds
        addSubview(view)
        
        addConstraints(NSLayoutConstraint.copyLayout(from: self, for: view))
    }
    
    class func fromNib<T: NSView>() -> T? {
        var topLevel: NSArray?
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: String(describing: T.self)), owner: nil, topLevelObjects: &topLevel)
        return topLevel?.firstObject as? T
    }
    
    @discardableResult
    func loadNib(namedAfter clazz: Any) -> Bool {
        return Bundle.main.loadNibNamed(NSNib.Name(rawValue: String(describing: type(of: clazz))), owner: self, topLevelObjects: nil)
    }
    
    var isInWindowResponderChain: Bool {
        var responder = window?.firstResponder
        while responder != nil {
            if self == responder {
                return true
            }
            responder = responder?.nextResponder
        }

        return false
    }
}

extension NSImageView {
    func transitionWithImage(image: NSImage?, duration: Double = 0.2) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        
        wantsLayer = true
        layer?.add(transition, forKey: kCATransition)
        
        self.image = image
    }
}

extension UserDefaults {
    func consume(toggle: String) -> Bool {
        let consumed = bool(forKey: toggle)
        if !consumed { set(true, forKey: toggle) }
        return !consumed
    }
}

extension NSSplitView {
    func toggleSubviewHidden(_ view: NSView) {
        if isSubviewCollapsed(view) {
            view.isHidden = false
        }
        else {
            view.isHidden = true
        }
    }
}

extension CALayer {
    
    func addBorder(edge: NSRectEdge, color: NSColor, thickness: CGFloat) {
        let border = CALayer()
        
        switch edge {
        case .minY:
            border.frame = CGRect(x: 0, y: 0, width: frame.width, height: thickness)
        case .maxY:
            border.frame = CGRect(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
        case .minX:
            border.frame = CGRect(x: 0, y: 0, width: thickness, height: frame.height)
        case .maxX:
            border.frame = CGRect(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
        }
        
        border.backgroundColor = color.cgColor;
        
        addSublayer(border)
    }
}

extension OSStatus {
    func explode() throws {
        guard self != 0 else {
            return
        }
        
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(self), userInfo: nil)
    }
}

extension NSLayoutConstraint {
    static func copyLayout(from container: NSView, for view: NSView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: 0),
        ]
    }
    
    static func center(in container: NSView, for view: NSView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: container, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: container, attribute: .centerY, multiplier: 1, constant: 0),
        ]
    }
}

extension NSObject {
    open func bind<Object, Source>(_ binding: NSBindingName, to observable: Object, withKeyPath keyPath: KeyPath<Object, Source>, options: [NSBindingOption: Any] = [:], transform: ((Source) -> AnyObject?)? = nil) {
        var options = options
        if let transform = transform {
            options[.valueTransformer] = SimpleTransformer<Source, AnyObject>(there: { transform($0!) })
        }
        
        bind(binding, to: observable, withKeyPath: keyPath._kvcKeyPathString!, options: options)
    }
}

extension CFTimeInterval {
    static func seconds(_ seconds: CFTimeInterval) -> CFTimeInterval {
        return seconds
    }
}

extension DateFormatter {
    convenience init(format: String) {
        self.init()
        self.dateFormat = format
    }
}
