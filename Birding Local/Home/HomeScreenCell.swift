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
        view.backgroundColor = Colors.AccentWhite.color
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
        label.textColor = Colors.PrimaryBlue.color
        label.font = Fonts.SFProBold.font(with: 18)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.AccentGray.color
        label.font = Fonts.SFProMedium.font(with: 14)
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
        backgroundColor = Colors.PrimaryBlue.color

        contentView.addSubview(contentArea)
        contentArea.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-80)
            $0.top.bottom.equalToSuperview().inset(15)
        }

        contentView.addSubview(birdImage)
        birdImage.snp.makeConstraints {
            // adjust when adding play button
            $0.trailing.equalTo(-16)
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
        nameLabel.text = sighting.comName
        timestampLabel.text = sighting.obsDt

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
            birdImage.image = UIImage(named: "DefaultBird")
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
