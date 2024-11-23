//
//  InfoWindowView.swift
//
//
//  Created by Jonathan on 30/08/2024.
//

import UIKit
import SafariServices

class CustomInfoWindow: UIView {
    private let titleLabel = UILabel()
    private let decibelLabel = UILabel()
    private let decibelDescriptionLabel = UILabel() // New label for noise level description
    private let decibelStack = UIStackView() // Stack view to hold decibel label and description
    private let conversationView = UIView()
    private let conversationIcon = UIImageView()
    private let conversationLabel = UILabel()
    private let topNoisesView = UIView()
    private let topNoisesIcon = UIImageView()
    private let topNoisesLabel = UILabel()
    private let topNoisesList = UIStackView()
    private let buttonStackView = UIStackView()
    private let googleMapsButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    
    var onTap: (() -> Void)?
    var onGoogleMapsTap: (() -> Void)?
    var onShareTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10
        
        // Set up decibel stack view
        decibelStack.axis = .vertical
        decibelStack.alignment = .trailing
        decibelStack.spacing = 2
        decibelStack.addArrangedSubview(decibelLabel)
        decibelStack.addArrangedSubview(decibelDescriptionLabel)
        
        // Change this line to use decibelStack instead of decibelLabel
        [titleLabel, decibelStack, conversationView, topNoisesView, buttonStackView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupTitleLabel()
        setupDecibelLabels()
        setupConversationView()
        setupTopNoisesView()
        setupButtons()
        
        setupConstraints()
    }
    
    private func setupTitleLabel() {
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold) // Slightly smaller initial font
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func setupDecibelLabels() {
        // Setup main decibel label
        decibelLabel.textColor = .label
        decibelLabel.font = .systemFont(ofSize: 24, weight: .bold)
        decibelLabel.textAlignment = .right
        decibelLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        decibelLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        // Setup description label
        decibelDescriptionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        decibelDescriptionLabel.textAlignment = .right
    }
    
    private func setupConversationView() {
        conversationView.layer.cornerRadius = 10 // Slightly smaller corner radius
        
        [conversationIcon, conversationLabel].forEach {
            conversationView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        conversationIcon.image = UIImage(systemName: "bubble.left.fill")
        conversationIcon.tintColor = .label
        conversationLabel.textColor = .label
        conversationLabel.font = .systemFont(ofSize: 15, weight: .medium) // Slightly smaller
    }
    
    private func setupTopNoisesView() {
        topNoisesView.backgroundColor = .secondarySystemBackground
        topNoisesView.layer.cornerRadius = 10
        
        [topNoisesIcon, topNoisesLabel, topNoisesList].forEach {
            topNoisesView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        topNoisesIcon.image = UIImage(systemName: "speaker.wave.3.fill")
        topNoisesIcon.tintColor = .secondaryLabel
        
        topNoisesLabel.text = "How often are noises reported?"
        topNoisesLabel.font = .systemFont(ofSize: 15, weight: .medium)
        topNoisesLabel.textColor = .secondaryLabel
        
        topNoisesList.axis = .vertical
        topNoisesList.spacing = 3 // Reduced spacing between noise items
        topNoisesList.alignment = .leading // Align items to the left
    }
    
    private func setupButtons() {
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 8 // Slightly reduced spacing
        
        [googleMapsButton, shareButton].forEach {
            buttonStackView.addArrangedSubview($0)
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            $0.layer.cornerRadius = 10
            $0.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            $0.setTitleColor(.systemBlue, for: .normal)
        }
        
        googleMapsButton.setImage(UIImage(systemName: "map.fill"), for: .normal)
        googleMapsButton.setTitle("Google Maps", for: .normal)
        googleMapsButton.addTarget(self, action: #selector(googleMapsTapped), for: .touchUpInside)
        
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.setTitle("Share", for: .normal)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title and decibel stack constraints
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: decibelStack.leadingAnchor, constant: -12),
            
            decibelStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            decibelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            decibelStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            
            // Conversation view with reduced spacing
            conversationView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            conversationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            conversationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            conversationView.heightAnchor.constraint(equalToConstant: 44), // Slightly reduced height
            
            conversationIcon.leadingAnchor.constraint(equalTo: conversationView.leadingAnchor, constant: 10),
            conversationIcon.centerYAnchor.constraint(equalTo: conversationView.centerYAnchor),
            conversationIcon.widthAnchor.constraint(equalToConstant: 20),
            conversationIcon.heightAnchor.constraint(equalToConstant: 20),
            
            conversationLabel.leadingAnchor.constraint(equalTo: conversationIcon.trailingAnchor, constant: 8),
            conversationLabel.centerYAnchor.constraint(equalTo: conversationView.centerYAnchor),
            
            // Top noises view with optimized spacing
            topNoisesView.topAnchor.constraint(equalTo: conversationView.bottomAnchor, constant: 12),
            topNoisesView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topNoisesView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            topNoisesIcon.topAnchor.constraint(equalTo: topNoisesView.topAnchor, constant: 10),
            topNoisesIcon.leadingAnchor.constraint(equalTo: topNoisesView.leadingAnchor, constant: 10),
            topNoisesIcon.widthAnchor.constraint(equalToConstant: 20),
            topNoisesIcon.heightAnchor.constraint(equalToConstant: 20),
            
            topNoisesLabel.centerYAnchor.constraint(equalTo: topNoisesIcon.centerYAnchor),
            topNoisesLabel.leadingAnchor.constraint(equalTo: topNoisesIcon.trailingAnchor, constant: 8),
            
            topNoisesList.topAnchor.constraint(equalTo: topNoisesIcon.bottomAnchor, constant: 8),
            topNoisesList.leadingAnchor.constraint(equalTo: topNoisesView.leadingAnchor, constant: 10),
            topNoisesList.trailingAnchor.constraint(equalTo: topNoisesView.trailingAnchor, constant: -10),
            topNoisesList.bottomAnchor.constraint(equalTo: topNoisesView.bottomAnchor, constant: -10),
            
            // Button stack view with reduced spacing
            buttonStackView.topAnchor.constraint(equalTo: topNoisesView.bottomAnchor, constant: 12),
            buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44) // Slightly reduced height
        ])
    }
    
    func configure(with data: VenueNoiseData) {
        titleLabel.text = data.venueName
        decibelLabel.text = "\(data.noiseLevel) dB"
        
        let noiseLevel = Double(data.noiseLevel)
        let color = getColorForNoiseLevel(noiseLevel)
        decibelLabel.textColor = color
        
        // Configure the description label
        let description = getNoiseDescription(for: noiseLevel)
        decibelDescriptionLabel.text = description
        decibelDescriptionLabel.textColor = color
        
        let conversationColor = getColorForConversationDifficulty(data.conversationEase)
        conversationView.backgroundColor = conversationColor.withAlphaComponent(0.1)
        conversationIcon.tintColor = conversationColor
        conversationLabel.textColor = conversationColor
        conversationLabel.text = "Conversation: \(data.conversationEase)"
        
        // Clear existing noise labels
        topNoisesList.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add noise labels with optimized appearance
        data.topNoises.prefix(3).forEach { noise, percentage in
            let noiseLabel = UILabel()
            noiseLabel.text = "\(noise): \(percentage)%"
            noiseLabel.font = .systemFont(ofSize: 13)
            noiseLabel.textColor = .secondaryLabel
            topNoisesList.addArrangedSubview(noiseLabel)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc private func googleMapsTapped() {
        onGoogleMapsTap?()
    }
    
    @objc private func shareTapped() {
        onShareTap?()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    private func getNoiseDescription(for db: Double) -> String {
        switch db {
        case ..<70:
            return "Silent"
        case 70..<76:
            return "Moderate"
        case 76..<80:
            return "Loud"
        default:
            return "Very Loud"
        }
    }
    
    private func getColorForNoiseLevel(_ db: Double) -> UIColor {
        switch db {
        case ..<70:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 2/255, green: 226/255, blue: 97/255, alpha: 1) : UIColor(red: 2/255, green: 180/255, blue: 77/255, alpha: 1)
            }
        case 70..<76:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 255/255, green: 212/255, blue: 0, alpha: 1) : UIColor(red: 204/255, green: 169/255, blue: 0, alpha: 1)
            }
        case 76..<80:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 213/255, green: 94/255, blue: 23/255, alpha: 1) : UIColor(red: 170/255, green: 75/255, blue: 18/255, alpha: 1)
            }
        default:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 209/255, green: 33/255, blue: 19/255, alpha: 1) : UIColor(red: 167/255, green: 26/255, blue: 15/255, alpha: 1)
            }
        }
    }
    
    private func getColorForConversationDifficulty(_ difficulty: String) -> UIColor {
        switch difficulty {
        case "Comfortable":
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 67/255.0, green: 190/255.0, blue: 90/255.0, alpha: 1) : UIColor(red: 53/255.0, green: 152/255.0, blue: 72/255.0, alpha: 1)
            }
        case "Manageable":
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 232/255.0, green: 185/255.0, blue: 5/255.0, alpha: 1) : UIColor(red: 185/255.0, green: 148/255.0, blue: 4/255.0, alpha: 1)
            }
        case "Challenging":
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 236/255.0, green: 55/255.0, blue: 45/255.0, alpha: 1) : UIColor(red: 188/255.0, green: 44/255.0, blue: 36/255.0, alpha: 1)
            }
        default:
            return .label
        }
    }
}

struct VenueNoiseData {
    let venueName: String
    let noiseLevel: Int
    let conversationEase: String
    let topNoises: [(String, Int)]  // Now the Int represents the actual percentage
}
