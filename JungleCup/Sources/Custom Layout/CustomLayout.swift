/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

final class CustomLayout: UICollectionViewLayout {
  
  enum Element: String {
    case header
    case menu
    case sectionHeader
    case sectionFooter
    case cell
    
    var id: String {
      return self.rawValue
    }
    
    var kind: String {
      return "Kind\(self.rawValue.capitalized)"
    }
  }
  
  override class public var layoutAttributesClass: AnyClass {
    return CustomLayoutAttributes.self
  }
  
  override var collectionViewContentSize: CGSize {
    return CGSize(width: collectionViewWidth, height: contentHeight)
  }
  
  var settings = CustomLayoutSettings()
  private var oldBounds = CGRect.zero
  private var contentHeight = CGFloat()
  private var cache = [Element: [IndexPath: CustomLayoutAttributes]]()
  private var visibleLayoutAttributes = [CustomLayoutAttributes]()
  private var zIndex = 0
  
  private var collectionViewHeight: CGFloat {
    return collectionView!.frame.height
  }
  
  private var collectionViewWidth: CGFloat {
    return collectionView!.frame.width
  }
  
  private var cellHeight: CGFloat {
    guard let itemSize = settings.itemSize else { return collectionViewHeight }
    return itemSize.height
  }
  
  private var cellWidth: CGFloat {
    guard let itemSize = settings.itemSize else { return collectionViewWidth }
    return itemSize.width
  }
  
  private var headerSize: CGSize {
    guard let headerSize = settings.headerSize else { return .zero }
    return headerSize
  }
  
  private var menuSize: CGSize {
    guard let menuSize = settings.menuSize else { return .zero }
    return menuSize
  }
  
  private var sectionsHeaderSize: CGSize {
    guard let sectionsHeaderSize = settings.sectionsHeaderSize else { return .zero }
    return sectionsHeaderSize
  }
  
  private var sectionsFooterSize: CGSize {
    guard let sectionsFooterSize = settings.sectionsFooterSize else { return .zero }
    return sectionsFooterSize
  }
  
  private var contentOffset: CGPoint {
    return collectionView!.contentOffset
  }
}
// MARK: Layout Core Process
extension CustomLayout {
  override func prepare() {
    guard let collectionView = collectionView, cache.isEmpty else { return  }
    prepareCache()
    contentHeight = 0
    zIndex = 0
    oldBounds = collectionView.bounds
    let itemSize = CGSize(width: cellWidth, height: cellHeight)
    
    let headerAttributes = CustomLayoutAttributes(forSupplementaryViewOfKind: Element.header.kind, with: IndexPath(item: 0, section: 0))
    prepareElement(size: headerSize, type: .header, attributes: headerAttributes)
    
    let menuAttributes = CustomLayoutAttributes(forSupplementaryViewOfKind: Element.menu.kind, with: IndexPath(item: 0, section: 0))
    prepareElement(size: menuSize, type: .menu, attributes: menuAttributes)
    
    for section in 0..<collectionView.numberOfSections {
      let sectionHeaderAttributes = CustomLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath(item: 0, section: section))
      prepareElement(size: sectionsHeaderSize, type: .sectionHeader, attributes: sectionHeaderAttributes)
      
      for item in 0..<collectionView.numberOfItems(inSection: section) {
        let cellIndexPath = IndexPath(item: item, section: section)
        let attributes = CustomLayoutAttributes(forCellWith: cellIndexPath)
        let lineInterSpace = settings.minimumLineSpacing
        attributes.frame = CGRect(
          x: 0 + settings.minimumInteritemSpacing,
          y: contentHeight + lineInterSpace,
          width: itemSize.width,
          height: itemSize.height
        )
        attributes.zIndex = zIndex
        contentHeight = attributes.frame.maxY
        cache[.cell]?[cellIndexPath] = attributes
        zIndex += 1
      }
      
      let sectionFooterAttributes = CustomLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: IndexPath(item: 1, section: section))
      prepareElement(size: sectionsFooterSize, type: .sectionFooter, attributes: sectionFooterAttributes)
    }
    updateZIndex()
  }
  
  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    if oldBounds.size != newBounds.size { cache.removeAll(keepingCapacity: true) }
    return true
  }
  
  private func updateZIndex() {
    guard let sectionHeaders = cache[.sectionHeader] else { return }
    
    var sectionHeadersZIndex = zIndex
    for (_, attributes) in sectionHeaders {
      attributes.zIndex = sectionHeadersZIndex
      sectionHeadersZIndex += 1
    }
    cache[.menu]?.first?.value.zIndex = sectionHeadersZIndex
  }
  
  private func prepareElement(size: CGSize, type: Element, attributes: CustomLayoutAttributes) {
    guard size != .zero else { return }
    attributes.initialOrigin = CGPoint(x: 0, y: contentHeight)
    attributes.frame = CGRect(origin: attributes.initialOrigin, size: size)
    
    attributes.zIndex = zIndex
    zIndex += 1
    
    contentHeight = attributes.frame.maxY
    
    cache[type]?[attributes.indexPath] = attributes
  }
  
  private func prepareCache() {
    cache.removeAll(keepingCapacity: true)
    cache[.header] = [IndexPath: CustomLayoutAttributes]()
    cache[.menu] = [IndexPath: CustomLayoutAttributes]()
    cache[.sectionHeader] = [IndexPath: CustomLayoutAttributes]()
    cache[.sectionFooter] = [IndexPath: CustomLayoutAttributes]()
    cache[.cell] = [IndexPath: CustomLayoutAttributes]()
  }
}

// MARK: Providing attributes to the collection
extension CustomLayout {
  override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    switch elementKind {
    case UICollectionElementKindSectionHeader: return cache[.sectionHeader]?[indexPath]
    case UICollectionElementKindSectionFooter: return cache[.sectionFooter]?[indexPath]
    case Element.header.kind: return cache[.header]?[indexPath]
    default: return cache[.menu]?[indexPath]
    }
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return cache[.cell]?[indexPath]
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let collectionView = collectionView else { return nil }
    visibleLayoutAttributes.removeAll(keepingCapacity: true)
    let halfHeight = collectionViewHeight * 0.5
    let halfCellHeight = cellHeight * 0.5
    
    for (type, elementInfos) in cache {
      for (indexPath, attributes) in elementInfos {
        attributes.parallax = .identity
        attributes.transform = .identity
        updateSupplementaryView(
          type: type,
          attributes: attributes,
          collectionView: collectionView,
          indexPath: indexPath
        )
        if attributes.frame.intersects(rect) {
          if type == .cell , settings.isParallaxOnCellsEnabled {
            updateCells(attributes: attributes, halfHeight: halfHeight, halfCellHeight: halfCellHeight)
          }
          visibleLayoutAttributes.append(attributes)
        }
      }
    }
    return visibleLayoutAttributes
  }
  
  private func updateCells(attributes: CustomLayoutAttributes, halfHeight: CGFloat, halfCellHeight: CGFloat) {
    let cellDistanceFromCenter = attributes.center.y - contentOffset.y - halfHeight
    let parallaxOffset = -(settings.maxParallaxOffset * cellDistanceFromCenter)
      / (halfHeight + halfCellHeight)
    let boundedParallaxOffset = min(
      max(-settings.maxParallaxOffset, parallaxOffset),
      settings.maxParallaxOffset)
    attributes.parallax = CGAffineTransform(translationX: 0, y: boundedParallaxOffset)
  }
  
  private func updateSupplementaryView(type: Element, attributes: CustomLayoutAttributes, collectionView: UICollectionView, indexPath: IndexPath) {
    if type == .sectionHeader, settings.isSectionHeadersSticky {
      let upperLimit = CGFloat(collectionView.numberOfItems(inSection: indexPath.section)) * (cellHeight + settings.minimumLineSpacing)
      let menuOffset = settings.isMenuSticky ? menuSize.height : 0
      let y = min(upperLimit, max(0, contentOffset.y - attributes.initialOrigin.y + menuOffset))
      attributes.transform = CGAffineTransform(translationX: 0, y: y)
    }
    else if type == .header, settings.isHeaderStretchy {
      let updatedHeight = min(collectionView.frame.height, max(headerSize.height, headerSize.height - contentOffset.y))
      let scaleFactor = updatedHeight / headerSize.height
      let delta = (updatedHeight - headerSize.height) / 2
      let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
      let translation = CGAffineTransform(translationX: 0, y:
        min(contentOffset.y, headerSize.height) + delta
      )
      attributes.transform = scale.concatenating(translation)
      if settings.isAlphaOnHeaderActive {
        attributes.headerOverlayAlpha = min(settings.headerOverlayMaxAlphaValue, contentOffset.y / headerSize.height)
      }
    }
    else if type == .menu, settings.isMenuSticky {
      attributes.transform = CGAffineTransform(translationX: 0, y: max(attributes.initialOrigin.y, contentOffset.y) - headerSize.height)
    }
  }
}
