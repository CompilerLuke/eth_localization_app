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
    private lazy var localizationService : LocalizationServiceDevice = LocalizationServiceDevice()
    private lazy var buildingService : BuildingServiceDevice = BuildingServiceDevice()
    private lazy var navigationService : NavigationServiceDevice = { NavigationServiceDevice(buildingService: buildingService) }()
    private lazy var imuService : IMUService = IMUService()
    
    func createLocalizationService() -> LocalizationService { return localizationService }
    func createBuildingService() -> BuildingService { return buildingService }
    func createNavigationService() -> NavigationService { return navigationService }
    func createImuService() -> IMUService { return imuService }
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
