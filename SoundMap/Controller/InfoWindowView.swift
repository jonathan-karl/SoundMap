//
//  InfoWindowView.swift
//
//
//  Created by Jonathan on 30/08/2024.
//

import UIKit

class CustomInfoWindow: UIView {
    private let titleLabel = UILabel()
    private let decibelLabel = UILabel()
    private let conversationTitleLabel = UILabel()
    private let conversationValueLabel = UILabel()
    private let topNoisesTitleLabel = UILabel()
    private let topNoisesValueLabel = UILabel()

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        [titleLabel, decibelLabel, conversationTitleLabel, conversationValueLabel, topNoisesTitleLabel, topNoisesValueLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        decibelLabel.font = UIFont.boldSystemFont(ofSize: 20)
        decibelLabel.textAlignment = .right
        
        conversationTitleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        conversationTitleLabel.text = "Conversation Difficulty:"
        
        conversationValueLabel.font = UIFont.systemFont(ofSize: 12)
        
        topNoisesTitleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        topNoisesTitleLabel.text = "Top Noises:"
        
        topNoisesValueLabel.font = UIFont.systemFont(ofSize: 12)
        topNoisesValueLabel.numberOfLines = 0

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: decibelLabel.leadingAnchor, constant: -12),

            decibelLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            decibelLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            decibelLabel.widthAnchor.constraint(equalToConstant: 90),

            conversationTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            conversationTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            conversationValueLabel.topAnchor.constraint(equalTo: conversationTitleLabel.bottomAnchor, constant: 4),
            conversationValueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            conversationValueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            topNoisesTitleLabel.topAnchor.constraint(equalTo: conversationValueLabel.bottomAnchor, constant: 12),
            topNoisesTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            topNoisesValueLabel.topAnchor.constraint(equalTo: topNoisesTitleLabel.bottomAnchor, constant: 4),
            topNoisesValueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            topNoisesValueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            topNoisesValueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        onTap?()
    }

    func configure(with data: VenueNoiseData) {
        titleLabel.text = data.venueName
        
        decibelLabel.text = "\(data.noiseLevel) dB"
        decibelLabel.textColor = getColorForNoiseLevel(Double(data.noiseLevel))

        conversationValueLabel.text = data.conversationEase
        conversationValueLabel.textColor = getColorForConversationDifficulty(data.conversationEase)

        let noisesText = data.topNoises.enumerated().map { index, noise in
            return "\(index + 1). \(noise.0): \(noise.1)%"
        }.joined(separator: "\n")
        topNoisesValueLabel.text = noisesText

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func getColorForNoiseLevel(_ db: Double) -> UIColor {
        switch db {
        case ..<70:
            return UIColor(red: 2/255, green: 226/255, blue: 97/255, alpha: 1) // Green
        case 70..<76:
            return UIColor(red: 255/255, green: 212/255, blue: 0, alpha: 1) // Yellow
        case 76..<80:
            return UIColor(red: 213/255, green: 94/255, blue: 23/255, alpha: 1) // Orange
        default:
            return UIColor(red: 209/255, green: 33/255, blue: 19/255, alpha: 1) // Red
        }
    }

    private func getColorForConversationDifficulty(_ difficulty: String) -> UIColor {
        switch difficulty {
        case "Comfortable":
            return UIColor(red: 67/255.0, green: 190/255.0, blue: 90/255.0, alpha: 1)
        case "Manageable":
            return UIColor(red: 232/255.0, green: 185/255.0, blue: 5/255.0, alpha: 1)
        case "Challenging":
            return UIColor(red: 236/255.0, green: 55/255.0, blue: 45/255.0, alpha: 1)
        default:
            return .black
        }
    }
}

class SoundwaveView: UIView {
    private var bars: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBars() {
        let barCount = 16
        let barWidth: CGFloat = 4
        let spacing: CGFloat = 2
        
        for i in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1) // Blue color
            bar.layer.cornerRadius = barWidth / 2
            addSubview(bar)
            bars.append(bar)
            
            bar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: bottomAnchor),
                bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(i) * (barWidth + spacing)),
                bar.widthAnchor.constraint(equalToConstant: barWidth)
            ])
        }
    }
    
    func setNoiseLevel(_ level: Int) {
        let maxHeight = bounds.height
        let heights: [CGFloat] = [15, 25, 35, 45, 55, 45, 35, 25, 15, 25, 35, 45, 55, 45, 35, 25]
        
        for (index, bar) in bars.enumerated() {
            let height = heights[index % heights.count] * maxHeight / 100
            bar.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}

class MetricView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor(red: 0.941, green: 0.988, blue: 0.941, alpha: 1) // Light green
        layer.cornerRadius = 8
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        iconView.tintColor = UIColor(red: 0, green: 0.588, blue: 0, alpha: 1) // Green color
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor(red: 0, green: 0.588, blue: 0, alpha: 1) // Green color
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        valueLabel.textColor = UIColor(red: 0, green: 0.392, blue: 0, alpha: 1) // Dark green
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            valueLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8)
        ])
    }
    
    func configure(title: String, value: String) {
        iconView.image = UIImage(systemName: "message")
        titleLabel.text = title
        valueLabel.text = value
    }
}

class TopNoisesView: UIView {
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor(red: 0.98, green: 0.949, blue: 1, alpha: 1) // Light purple
        layer.cornerRadius = 8
        
        addSubview(titleLabel)
        addSubview(stackView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.502, green: 0, blue: 0.502, alpha: 1) // Purple color
        
        stackView.axis = .vertical
        stackView.spacing = 4
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with noises: [(String, Int)]) {
        titleLabel.text = "Top Noises"
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (name, percentage) in noises {
            let noiseView = NoiseSourceView(name: name, percentage: percentage)
            stackView.addArrangedSubview(noiseView)
        }
    }
}

class NoiseSourceView: UIView {
    private let nameLabel = UILabel()
    private let percentageLabel = UILabel()
    
    init(name: String, percentage: Int) {
        super.init(frame: .zero)
        setupViews()
        configure(name: name, percentage: percentage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(nameLabel)
        addSubview(percentageLabel)
        
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1) // Dark gray
        
        percentageLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        percentageLabel.textColor = UIColor(red: 0.502, green: 0, blue: 0.502, alpha: 1) // Purple color
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(name: String, percentage: Int) {
        nameLabel.text = name
        percentageLabel.text = "\(percentage)%"
    }
}

struct VenueNoiseData {
    let venueName: String
    let noiseLevel: Int
    let conversationEase: String
    let topNoises: [(String, Int)]  // Now the Int represents percentage
}
