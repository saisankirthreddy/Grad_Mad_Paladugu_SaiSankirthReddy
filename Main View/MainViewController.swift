

import UIKit
import PhotosUI

class MainViewController: UIViewController, PHPickerViewControllerDelegate {
    var firstRun = true

    let imagePredictor = ImagePredictor()

    let imageView = UIImageView()
    
    let label = UILabel()
    
    let button = UIButton()


    var photoPicker: PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images

        let photoPicker = PHPickerViewController(configuration: config)
        photoPicker.delegate = self

        return photoPicker
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Upload Photo", for: .normal)
        button.backgroundColor = .black
        button.titleLabel?.font = .systemFont(ofSize: 30)
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        view.addSubview(button)
        button.centerYAnchor.constraint(equalTo: imageView.centerYAnchor, constant: 300).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: false)

        guard let result = results.first else {
            return
        }

        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            if let error = error {
                print("Photo picker error: \(error)")
                return
            }

            guard let photo = object as? UIImage else {
                fatalError("The Photo Picker's image isn't a/n \(UIImage.self) instance.")
            }

            self.userSelectedPhoto(photo)
        }
    }
}

extension MainViewController {
    
    @objc func buttonTapped() {
        present(photoPicker, animated: true)
    }
}

extension MainViewController {
    
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    ///
    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.label.backgroundColor = .white
            self.label.text = message
        }

//        if firstRun {
//            DispatchQueue.main.async {
//                self.firstRun = false
//                self.predictionLabel.superview?.isHidden = false
//                self.startupPrompts.isHidden = true
//            }
//        }
    }
    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
    /// - Parameter photo: A photo from the camera or photo library.
    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("Making predictions for the photo...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }

}

extension MainViewController {
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.joined(separator: "\n")
        updatePredictionLabel(predictionString)
    }

    /// Converts a prediction's observations into human-readable strings.
    /// - Parameter observations: The classification observations from a Vision request.
    /// - Tag: formatPredictions
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(2).map { prediction in
            var name = prediction.classification

            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }

            return "\(name) - \(prediction.confidencePercentage)%"
        }

        return topPredictions
    }
}
