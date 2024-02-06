//
//  HomeScreenCell.swift
//  Birding Local
//
//  Created by Kenny Barone on 10/12/23.
//

import Foundation
import UIKit
import SnapKit
import SDWebImage

class HomeScreenCell: UITableViewCell {
    private lazy var contentArea: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(color: .AccentWhite)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var nameAndTimestampContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(color: .PrimaryBlue)
        label.font = TextStyle.boldedHeader.uiFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(color: .AccentGray)
        label.font = TextStyle.label.uiFont
        return label
    }()

    private lazy var birdImage: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 110 / 2
        view.backgroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.00)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear

        contentView.addSubview(contentArea)
        contentArea.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-80)
            $0.top.bottom.equalToSuperview().inset(15)
        }

        contentView.addSubview(birdImage)
        birdImage.snp.makeConstraints {
            // adjust when adding play button
            $0.trailing.equalTo(-24)
            $0.top.bottom.equalToSuperview().inset(4)
            $0.height.width.equalTo(110)
        }

        contentArea.addSubview(nameAndTimestampContainer)
        nameAndTimestampContainer.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(birdImage.snp.leading).offset(-16)
            $0.centerY.equalToSuperview()
        }

        nameAndTimestampContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.equalToSuperview()
        }

        nameAndTimestampContainer.addSubview(timestampLabel)
        timestampLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview()
        }
    }

    func configure(sighting: BirdSighting) {
        let attributes = [NSAttributedString.Key.kern: -0.45]
        nameLabel.attributedText = NSAttributedString(string: sighting.commonName, attributes: attributes)
        timestampLabel.attributedText = NSAttributedString(string: sighting.timestamp, attributes: attributes)

        //TODO: format timestamp

        if let url = sighting.imageURL, url != "" {
            let transformer = SDImageResizingTransformer(size: CGSize(width: 200, height: 200), scaleMode: .aspectFill)
            birdImage.sd_setImage(
                with: URL(string: url),
                placeholderImage: UIImage(color: .lightGray),
                options: .highPriority,
                context: [.imageTransformer: transformer]
            )
        } else {
            birdImage.image = UIImage(asset: .DefaultBird)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        birdImage.sd_cancelCurrentImageLoad()
    }
}
