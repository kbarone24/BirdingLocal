//
//  HomeScreenTableViewHeader.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/14/23.
//

import Foundation
import UIKit

class HomeScreenTableViewHeader: UITableViewHeaderFooterView {
    private var headerLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(color: .AccentWhite)
        label.font = TextStyle.heroHeader.uiFont
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints {
            $0.leading.equalTo(20)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(title: String) {
        headerLabel.attributedText = NSMutableAttributedString(string: "Nearby Sightings", attributes: [NSAttributedString.Key.kern: -0.41]) 
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
