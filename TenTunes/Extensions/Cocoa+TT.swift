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
        
        return tiffRepresentation.flatMap(NSBitmapImageRep.init)
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
        
    func tableColumn(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> NSTableColumn? {
        tableColumns[safe: column(withIdentifier: identifier)]
    }
    
    func scrollRowToTop(_ row: Int) {
        let headerPart = headerView?.frame.height ?? 0
        scroll(NSPoint(x: 0, y: CGFloat(row) * (rowHeight + intercellSpacing.height) - headerPart))
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
    
    convenience init(title: String, action: Selector?, target: AnyObject) {
        self.init(title: title, action: action, keyEquivalent: "")
        self.target = target
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
    
    var hasFirstResponder: Bool {
        return firstResponder != nil && firstResponder != self
    }
}

extension NSOutlineView {
    func edit(row: Int, with event: NSEvent?, select: Bool) {
        editColumn(0, row: row, with: event, select: select)
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
        
        let positioned = items.compactMap(position).sorted {
            return $0.0 < $1.0
        }
        
        for (pos, parent) in positioned {
            insertItems(at: IndexSet(integer: pos), inParent: parent, withAnimation: .slideUp)
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
        Bundle.main.loadNibNamed(NSNib.Name(String(describing: T.self)), owner: nil, topLevelObjects: &topLevel)
        return topLevel?.firstObject as? T
    }
    
    @discardableResult
    func loadNib(namedAfter clazz: Any) -> Bool {
        return Bundle.main.loadNibNamed(NSNib.Name(String(describing: type(of: clazz))), owner: self, topLevelObjects: nil)
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
    
    var inheritedAppearance: NSAppearance? {
        return window?.appearance
    }

    func byAppearance<Type>(_ dict: [NSAppearance.Name?: Type]) -> Type {
        return dict[inheritedAppearance?.name] ?? dict[nil]!
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
    
    enum SplitSide {
        case left, right
    }
    
    func position(ofDividerAt index: Int) -> CGFloat {
        return subviews[index].frame.maxX
    }
    
    func adaptSubview(_ view: NSView, toMinSize minSize: CGFloat, from side: SplitSide) {
        let adjustment = minSize - view.frame.size.width
        guard adjustment > 0 else {
            return
        }
        
        guard let viewIndex = subviews.firstIndex(of: view) else {
            return
        }
        
        let dividerIndex = side == .left ? viewIndex - 1 : viewIndex
        let dividerAdjustment = side == .left ? -adjustment : adjustment
        
        let current = position(ofDividerAt: dividerIndex)
        setPosition(current + dividerAdjustment, ofDividerAt: dividerIndex)
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
        @unknown default:
            fatalError()
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

extension DispatchQueue {
    func perform(wait: Bool, block: @escaping () -> Void) {
        if Thread.isMainThread, self == DispatchQueue.main {
            block()
        }
        else if wait {
            sync(execute: block)
        }
        else {
            async(execute: block)
        }
    }
}
