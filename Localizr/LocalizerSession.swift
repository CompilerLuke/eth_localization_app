//
//  LocalizerSession.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation
import ARKit
import RealityKit

struct LocalizerResponse : Decodable {
    var pos : Point3
    //var node : Int
}


class LocalizationService {
    func localize(image: UIImage, onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        assert(false);
    }
}

class LocalizationServiceDevice : LocalizationService {
    override func localize(image: UIImage, onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        // todo
    }
}

class LocalizationServiceHTTP : LocalizationService {
    let serverURL : String
    
    init(serverURL : String) {
        self.serverURL = serverURL
    }
    
    let boundary = "example.boundary.\(ProcessInfo.processInfo.globallyUniqueString)"
    let fieldName = "upload_image"
    
    var headers: [String: String] {
        return [
            "Content-Type": "multipart/form-data; boundary=\(boundary)",
            "Accept": "application/json"
        ]
    }
    
    var parameters: [String: Any]? {
        return [:]
    }
    
    override func localize(image: UIImage, onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        let imageData = image.jpegData(compressionQuality: 1)!
        let mimeType = "image/jpeg" //imageData.mimeType!

        let url = URL(string: serverURL+"/localize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers // method: "POST", headers: headers)
        request.httpBody = createHttpBody(binaryData: imageData, mimeType: mimeType)
        
        let session = URLSession(configuration: .default)
        session.dataTask(with: request, completionHandler: jsonDecoderHandler(on_success: onSuccess, on_failure: onFailure)).resume()
    }
    
    private func createHttpBody(binaryData: Data, mimeType: String) -> Data {
        var postContent = "--\(boundary)\r\n"
        let fileName = "\(UUID().uuidString).jpeg"
        postContent += "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
        postContent += "Content-Type: \(mimeType)\r\n\r\n"

        var data = Data()
        guard let postData = postContent.data(using: .utf8) else { return data }
        data.append(postData)
        data.append(binaryData)

        if let parameters = parameters {
            var content = ""
            parameters.forEach {
                content += "\r\n--\(boundary)\r\n"
                content += "Content-Disposition: form-data; name=\"\($0.key)\"\r\n\r\n"
                content += "\($0.value)"
            }
            if let postData = content.data(using: .utf8) { data.append(postData) }
        }

        guard let endData = "\r\n--\(boundary)--\r\n".data(using: .utf8) else { return data }
        data.append(endData)
        return data
    }
}

class LocalizerSession : ObservableObject {
    weak var arView : ARView? = nil
    var localizerService : LocalizationService
    @Published var position: Point3? = Point3(x:0,y:0,z:0)
    
    init(localizationService : LocalizationService) {
        self.localizerService = localizationService
    }
    
    func localize() {
        print("Localizing!")
        
        guard let img = self.arView?.session.currentFrame?.capturedImage else {
            print("Could not aquire image")
            return
        }
        
        let ciimg = CIImage(cvImageBuffer: img)
        let image = UIImage(ciImage: ciimg)
        
        func on_success(data: LocalizerResponse) {
            DispatchQueue.main.async {
                self.position = data.pos
                print("New location ", data.pos.x, data.pos.y)
            }
        }
        
        func on_failure(err: String) {
            print(err)
        }
        
        self.localizerService.localize(image: image, onSuccess: on_success, onFailure: on_failure)
    }
}
