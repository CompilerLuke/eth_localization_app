//
//  LocalizerSession.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation
import ARKit
import RealityKit
import CoreMotion

struct LocalizerResponse : Decodable {
    var pos : Point3
    //var node : Int
}

class LocalizationService {
    func localize(image: UIImage, imuData: [String: Any], onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        assert(false);
    }
}

class LocalizationServiceDevice : LocalizationService {
    override func localize(image: UIImage, imuData: [String: Any], onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
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
    
    override func localize(image: UIImage, imuData: [String: Any], onSuccess: @escaping (LocalizerResponse) -> Void, onFailure: @escaping (String) -> Void) {
        let imageData = image.jpegData(compressionQuality: 1)!
        let mimeType = "image/jpeg" //imageData.mimeType!

        let url = URL(string: serverURL+"/localize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers // method: "POST", headers: headers)
        request.httpBody = createHttpBody(binaryData: imageData, mimeType: mimeType, imuData:imuData)
        
        let session = URLSession(configuration: .default)
        session.dataTask(with: request, completionHandler: jsonDecoderHandler(on_success: onSuccess, on_failure: onFailure)).resume()
    }
    
    private func createHttpBody(binaryData: Data, mimeType: String, imuData: [String: Any]) -> Data {
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

        // add IMU data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: imuData, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            var imuDataContent = "--\(boundary)\r\n"
            imuDataContent += "Content-Disposition: form-data; name=\"imuData\"\r\n"
            imuDataContent += "Content-Type: application/json\r\n\r\n"
            imuDataContent += jsonString
            imuDataContent += "\r\n"
            
            guard let postIMUData = imuDataContent.data(using: .utf8) else {return Data()}
            data.append(postIMUData)
        } catch {
            print("Error converting IMU data to json: \(error)")
        }

        guard let endData = "\r\n--\(boundary)--\r\n".data(using: .utf8) else { return data }
        data.append(endData)
        return data
    }
}

// struct to store IMU data in between localization queries
struct IMUData {
    var accelerometerData: [CMAcceleration] = []
    var gyroData: [CMRotationRate] = []
    var magnetometerData: [CMMagneticField] = []
}

class LocalizerSession : ObservableObject {
    weak var arView : ARView? = nil
    var localizerService : LocalizationService
    var manager: CMMotionManager
    var data: IMUData = IMUData()
    var queue: OperationQueue = OperationQueue()
    @Published var position: Point3? = Point3(x:0,y:0,z:0)
    
    init(localizationService : LocalizationService) {
        self.localizerService = localizationService
        self.manager = CMMotionManager()
        self.start_motion_updates()
    }
    
    // set up the collection of all motion data
    // everything will be appended into the list
    private func start_motion_updates() {
        self.manager.gyroUpdateInterval = 0.1
        self.manager.startGyroUpdates(to: queue) { [weak self] (data: CMGyroData?, error) in
            guard let strongSelf = self, let data = data else {return}
            DispatchQueue.main.async {
                strongSelf.data.gyroData.append(data.rotationRate)
            }
        }
        
        self.manager.accelerometerUpdateInterval = 0.1
        self.manager.startAccelerometerUpdates(to: queue) { [weak self] (data: CMAccelerometerData?, error) in
            guard let strongSelf = self, let data = data else {return}
            DispatchQueue.main.async {
                strongSelf.data.accelerometerData.append(data.acceleration)
            }
            
        }
        
        self.manager.magnetometerUpdateInterval = 0.1
        self.manager.startMagnetometerUpdates(to: queue) { [weak self] (data: CMMagnetometerData?, error) in
            guard let strongSelf = self, let data = data else {return}
            DispatchQueue.main.async {
                strongSelf.data.magnetometerData.append(data.magneticField)
            }
        }
    }

    
    // accumulated IMU data as json
    private func prepareIMUPayload() -> [String: Any] {
        var payload = [String: Any]()
        payload["accelerometer"] = data.accelerometerData.map { ["x": $0.x, "y": $0.y, "z": $0.z] }
        payload["gyroscope"] = data.gyroData.map { ["x": $0.x, "y": $0.y, "z": $0.z] }
        payload["magnetometer"] = data.magnetometerData.map { ["x": $0.x, "y": $0.y, "z": $0.z] }
        return payload
    }
    
    
    func localize() {
        print("Localizing!")
        
        guard let img = self.arView?.session.currentFrame?.capturedImage else {
            print("Could not aquire image")
            return
        }
        
        let ciimg = CIImage(cvImageBuffer: img)
        let image = UIImage(ciImage: ciimg)
        
        let imuData = prepareIMUPayload()
        
        func on_success(data: LocalizerResponse) {
            DispatchQueue.main.async {
                self.position = data.pos
                print("New location ", data.pos.x, data.pos.y)
                
                self.data = IMUData()
                print("Resetting accumulated IMU data")
            }
        }
        
        func on_failure(err: String) {
            print(err)
        }
        
        self.localizerService.localize(image: image, imuData: imuData, onSuccess: on_success, onFailure: on_failure)
    }
}
