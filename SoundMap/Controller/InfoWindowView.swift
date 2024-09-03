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
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10
        
        [titleLabel, decibelLabel, conversationView, topNoisesView, buttonStackView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        decibelLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        decibelLabel.textAlignment = .right
        
        setupConversationView()
        setupTopNoisesView()
        setupButtons()
        
        setupConstraints()
    }
    
    private func setupConversationView() {
        conversationView.layer.cornerRadius = 12
        
        [conversationIcon, conversationLabel].forEach {
            conversationView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        conversationIcon.image = UIImage(systemName: "bubble.left.fill")
        
        conversationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }
    
    private func setupTopNoisesView() {
        topNoisesView.backgroundColor = UIColor.systemGray6 // Light gray background
        topNoisesView.layer.cornerRadius = 12
        
        [topNoisesIcon, topNoisesLabel, topNoisesList].forEach {
            topNoisesView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        topNoisesIcon.image = UIImage(systemName: "speaker.wave.3.fill")
        topNoisesIcon.tintColor = .darkGray // Darker icon color
        
        topNoisesLabel.text = "Top Noises"
        topNoisesLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        topNoisesLabel.textColor = .darkGray // Darker text color
        
        topNoisesList.axis = .vertical
        topNoisesList.spacing = 4
    }
    
    private func setupButtons() {
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        
        [googleMapsButton, shareButton].forEach {
            buttonStackView.addArrangedSubview($0)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            $0.layer.cornerRadius = 12
            $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
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
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: decibelLabel.leadingAnchor, constant: -8),
            
            decibelLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            decibelLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            conversationView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            conversationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            conversationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            conversationView.heightAnchor.constraint(equalToConstant: 50),
            
            conversationIcon.leadingAnchor.constraint(equalTo: conversationView.leadingAnchor, constant: 12),
            conversationIcon.centerYAnchor.constraint(equalTo: conversationView.centerYAnchor),
            conversationIcon.widthAnchor.constraint(equalToConstant: 24),
            conversationIcon.heightAnchor.constraint(equalToConstant: 24),
            
            conversationLabel.leadingAnchor.constraint(equalTo: conversationIcon.trailingAnchor, constant: 8),
            conversationLabel.centerYAnchor.constraint(equalTo: conversationView.centerYAnchor),
            
            topNoisesView.topAnchor.constraint(equalTo: conversationView.bottomAnchor, constant: 12),
            topNoisesView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            topNoisesView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            topNoisesIcon.topAnchor.constraint(equalTo: topNoisesView.topAnchor, constant: 12),
            topNoisesIcon.leadingAnchor.constraint(equalTo: topNoisesView.leadingAnchor, constant: 12),
            topNoisesIcon.widthAnchor.constraint(equalToConstant: 24),
            topNoisesIcon.heightAnchor.constraint(equalToConstant: 24),
            
            topNoisesLabel.centerYAnchor.constraint(equalTo: topNoisesIcon.centerYAnchor),
            topNoisesLabel.leadingAnchor.constraint(equalTo: topNoisesIcon.trailingAnchor, constant: 8),
            
            topNoisesList.topAnchor.constraint(equalTo: topNoisesIcon.bottomAnchor, constant: 8),
            topNoisesList.leadingAnchor.constraint(equalTo: topNoisesView.leadingAnchor, constant: 12),
            topNoisesList.trailingAnchor.constraint(equalTo: topNoisesView.trailingAnchor, constant: -12),
            topNoisesList.bottomAnchor.constraint(equalTo: topNoisesView.bottomAnchor, constant: -12),
            
            buttonStackView.topAnchor.constraint(equalTo: topNoisesView.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
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
    
    func configure(with data: VenueNoiseData) {
        titleLabel.text = data.venueName
        decibelLabel.text = "\(data.noiseLevel) dB"
        decibelLabel.textColor = getColorForNoiseLevel(Double(data.noiseLevel))
        
        let conversationColor = getColorForConversationDifficulty(data.conversationEase)
        conversationView.backgroundColor = conversationColor.withAlphaComponent(0.1)
        conversationIcon.tintColor = conversationColor
        conversationLabel.textColor = conversationColor
        conversationLabel.text = "Conversation: \(data.conversationEase)"
        
        topNoisesList.arrangedSubviews.forEach { $0.removeFromSuperview() }
        data.topNoises.forEach { noise, percentage in
            let noiseLabel = UILabel()
            noiseLabel.text = "\(noise): \(percentage)%"
            noiseLabel.font = UIFont.systemFont(ofSize: 14)
            noiseLabel.textColor = .darkGray
            topNoisesList.addArrangedSubview(noiseLabel)
        }
        
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

struct VenueNoiseData {
    let venueName: String
    let noiseLevel: Int
    let conversationEase: String
    let topNoises: [(String, Int)]  // Now the Int represents percentage
}
