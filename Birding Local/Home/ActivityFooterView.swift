//
//  ActivityFooterView.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/15/23.
//

import Foundation
import UIKit

class ActivityFooterView: UIView {
    private(set) lazy var activityIndicator = UIActivityIndicatorView()

    override var isHidden: Bool {
        didSet {
            if isHidden {
                activityIndicator.stopAnimating()
            } else {
                activityIndicator.startAnimating()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        activityIndicator.color = .white
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
