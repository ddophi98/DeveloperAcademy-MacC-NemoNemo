//
//  PaperStorageLength.swift
//  RollingPaper
//
//  Created by 김동락 on 2022/11/15.
//

import UIKit

final class GiftStorageLength {
    static let paperThumbnailCornerRadius: CGFloat = 12
    static let headerWidth: CGFloat = 200 // 임시
    static let headerHeight: CGFloat = 29
    static let headerLeftMargin: CGFloat = 37
    static let sectionTopMargin: CGFloat = 16
    static let sectionBottomMargin: CGFloat = 48
    static let sectionRightMargin: CGFloat = 36
    static let sectionLeftMargin: CGFloat = 36
    static var paperThumbnailWidth: CGFloat = (UIScreen.main.bounds.width*0.75-(sectionLeftMargin+sectionRightMargin)) // 반응형
    static let paperThumbnailHeight: CGFloat = paperThumbnailWidth*0.16
    static let cellHorizontalSpace: CGFloat = 0
    static let cellVerticalSpace: CGFloat = 10
    static let labelSpacing: CGFloat = 10
}