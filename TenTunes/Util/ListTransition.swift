//
//  DifferenceAnimator.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

import Foundation

enum ListTransition<Element: Equatable> {
	case insert(rows: IndexSet)
	case remove(rows: IndexSet)
	case move(sequence: [(Int, Int)])
	case reload(previousSize: Int, newSize: Int)
	
	static func findBest(before: [Element]?, after: [Element]?, maxRows: Int = 100) -> ListTransition {
		let reload = ListTransition.reload(previousSize: before?.count ?? 0, newSize: after?.count ?? 0)
		
		guard let before = before, let after = after else {
			// Specifically a reload is requested
			return reload
		}
		
		
		if let (isBeforeSmaller, difference) = Self.difference(lhs: before, rhs: after) {
			guard difference.count <= maxRows else {
				return reload
			}
			
			if isBeforeSmaller {
				return .insert(rows: difference)
			}
			else {
				return .remove(rows: difference)
			}
		}
	
		if let sequence = Self.movement(before: before, after: after) {
			guard sequence.count <= maxRows else {
				return reload
			}

			return .move(sequence: sequence)
		}
		
		// No better way found
		return reload
	}
	
	static func difference(lhs: [Element], rhs: [Element]) -> (Bool, IndexSet)? {
		let leftSmaller = lhs.count < rhs.count
		let (left, right) = leftSmaller ? (lhs, rhs) : (rhs, lhs)
		var difference: [Int] = []
		difference.reserveCapacity(right.count - left.count)
		
		var rightIdx = -1
		
		for item in left {
			repeat {
				rightIdx += 1
				if rightIdx >= right.count {
					return nil
				}
				
				// Add current item
				if right[rightIdx] != item { difference.append(rightIdx) }
			}
				while right[rightIdx] != item
		}
		
		// Add the rest
		difference += Array<Int>((rightIdx + 1)..<right.count)
		
		return leftSmaller ? (true, IndexSet(difference)) : (false, IndexSet(difference))
	}
	
	static func movement(before: [Element], after: [Element]) -> [(Int, Int)]? {
		guard after.count == before.count else {
			return nil
		}
		
		// Direct approach
		guard after.count > 50 else {
			// Any more and it looks shit
			// Can reasonably do index(of)
			let indices = before.compactMap { after.firstIndex(of: $0) }
			// Everything has a unique index
			guard Set(indices).count == after.count else {
				return nil
			}
			var movement = indices.enumerated().map { ($0.0, $0.1) }
				//                .filter { $0.0 != $0.1 }
				.sorted { $0.1 < $1.1 }
			
			for i in 0..<movement.count {
				let (src, dst) = movement[i]
				movement[dst+1..<movement.count] = (movement[dst+1..<movement.count].map { (src2, dst2) in
					return (src2 + (src2 < src ? 1 : 0), dst2)
				}).fullSlice()
			}
			
			return movement.filter { $0.0 != $0.1 }
		}
		
		let (left, right) = (before, after)
		
		var leftIdx = 0
		var rightIdx = 0
		
		var bucket: [Int] = []
		var movements: [(Int, Int)] = []
		
		// We run through both lists, keeping an irregularity bucket
		// Whenever the objects aren't the same, we check if we can use the first bucket object -> Movement
		// Otherwise we put the current objects at the end of the bucket
		while leftIdx < right.count || rightIdx < right.count {
			if rightIdx < right.count, leftIdx < left.count, left[leftIdx] == right[rightIdx] {
				leftIdx += 1
				rightIdx += 1
			}
			else if rightIdx < right.count, let first = bucket.first, left[first] == right[rightIdx] {
				movements.append((bucket.removeFirst(), rightIdx))
				rightIdx += 1
			}
			else if leftIdx < left.count {
				bucket.append(leftIdx)
				leftIdx += 1
			}
			else {
				return nil
			}
		}
		
		return bucket.count == 0 ? movements.sorted { $0.1 > $1.1 } : nil
	}
}

extension ListTransition {
	func executeAnimationsInTableView(_ tableView: NSTableView) {
		switch self {
		case .reload:
			tableView.reloadData()
		case .remove(let rows):
			tableView.removeRows(at: IndexSet(rows), withAnimation: .slideDown)
		case .insert(let rows):
			tableView.insertRows(at: IndexSet(rows), withAnimation: .slideUp)
		case .move(let sequence):
			for (src, dst) in sequence {
				tableView.moveRow(at: src, to: dst)
			}
		}
	}
	
	func executeAnimationsInOutlineView(_ outlineView: NSOutlineView, childrenOf parent: Any?) {
		switch self {
		case .insert(let rows):
			outlineView.insertItems(at: rows, inParent: parent, withAnimation: .slideUp)
		case .remove(let rows):
			outlineView.removeItems(at: rows, inParent: parent, withAnimation: .slideDown)
		case .move(let sequence):
			for (src, dst) in sequence {
				outlineView.moveItem(at: src, inParent: parent, to: dst, inParent: parent)
			}
		case .reload(let previousSize, let newSize):
			// Animate size difference first
			if previousSize > newSize {
				outlineView.removeItems(at: IndexSet(integersIn: newSize ..< previousSize), inParent: parent, withAnimation: .slideDown)
			}
			else if newSize > previousSize {
				outlineView.insertItems(at: IndexSet(integersIn: previousSize ..< newSize), inParent: parent, withAnimation: .slideUp)
			}
			
			outlineView.reloadItems(at: IndexSet(integersIn: 0 ..< min(previousSize, newSize)), inParent: parent)
		}
	}
}
