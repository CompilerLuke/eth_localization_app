//
//  NetworkUtils.swift
//  localizr
//
//  Created by Antonella Calvia on 18/04/2024.
//

import Foundation

func jsonDecoderHandler<T: Decodable>(on_success:  @escaping (T) -> (), on_failure: @escaping (String) -> ()) -> (Data?, URLResponse?, Error?) -> Void {
    func handler(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            print("Error: \(error.localizedDescription)")
            on_failure("Error")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Invalid response")
            on_failure("Invalid response")
            return
        }
        
        guard let data = data else {
            print("No data")
            on_failure("No data")
            return
        }
        
        do {
            let result = try JSONDecoder().decode(T.self, from: data)
            on_success(result)
        } catch {
            print("Error decoding JSON: \(error)")
            on_failure("Error decoding json")
        }
    }
    
    return handler
}

func getRequest<T: Decodable>(path: String, on_success:  @escaping (T) -> (), on_failure: @escaping (String) -> ()) {
    guard let url = URL(string: path) else {
        print("Invalid URL")
        return
    }
    
    print("Logging path \(path)")
    URLSession.shared.dataTask(with: url, completionHandler: jsonDecoderHandler(on_success: on_success, on_failure: on_failure)).resume()
}

func getLocalJSON<T: Decodable>(path: String, on_success:  @escaping (T) -> (), on_failure: @escaping (String) -> ()) {
    guard let fileURL = Bundle.main.path(forResource: path, ofType: "json")
    else {
        on_failure("\(path) : Could not find")
        return
    }
    
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: fileURL), options: .mappedIfSafe)
    else {
        on_failure("\(path) : Could not create url")
        return
    }
    
    do {
        let result = try JSONDecoder().decode(T.self, from: data)
        on_success(result)
    } catch let jsonError as NSError {
        print(jsonError)
        on_failure("\(path) : Could not parse to type")
        return
    }
}
