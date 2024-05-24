//
//  SwiftFactory.swift
//  localizr
//
//  Created by Antonella Calvia on 16/05/2024.
//

import Foundation

protocol ServiceFactory {
    func createLocalizationService() -> LocalizationService
    func createBuildingService() -> BuildingService
    func createNavigationService() -> NavigationService
    func createImuService() -> IMUService
}

class ServiceFactoryFrontendOnly : ServiceFactory {
    func createLocalizationService() -> LocalizationService {
        return LocalizationServiceDevice()
    }
    
    func createBuildingService() -> BuildingService {
        return BuildingServiceDevice()
    }
    
    func createNavigationService() -> NavigationService {
        return NavigationServiceDevice()
    }
    
    func createImuService() -> IMUService {
        return IMUService()
    }
}

class ServiceFactoryHTTP : ServiceFactory {
    let serverURL : String
    
    init(serverURL : String) {
        self.serverURL = serverURL
    }
            
    func createLocalizationService() -> LocalizationService {
        return LocalizationServiceHTTP(serverURL : serverURL)
    }
            
    func createBuildingService() -> BuildingService {
        return BuildingServiceHTTP(serverURL: serverURL, building: 1)
    }
            
    func createNavigationService() -> NavigationService {
        return NavigationServiceHTTP(serverURL: serverURL)
    }
    
    func createImuService() -> IMUService {
        return IMUService()
    }
}

func createServiceFactory() -> any ServiceFactory {
    let mode = ProcessInfo.processInfo.environment["SERVICE_MODE", default: "DEVICE"]
    
    if(mode == "BACKEND") {
        let url = ProcessInfo.processInfo.environment["SERVER_URL", default: ""];
        return ServiceFactoryHTTP(serverURL: url)
    } else {
        return ServiceFactoryFrontendOnly()
    }
}
