//
//  TwilioAccessTokenFetcher.swift
//  SwiftVoiceCallKitQuickstart
//

import Foundation

class TwilioAccessTokenFetcher: NSObject {
    
    private let baseURLString = "https://staging.knowmeiq.com"
    // If your token server is written in PHP, accessTokenEndpoint needs .php extension at the end. For example : /accessToken.php
    private let accessTokenEndpoint = "/accessToken"
    private let identity = "alice"
    
    func fetchAccessToken(_ completion: (String?) -> Void) {
        let endpointWithIdentity = String(format: "%@?identity=%@", accessTokenEndpoint, identity)
        guard let accessTokenURL = URL(string: baseURLString + endpointWithIdentity) else {
            completion(nil)
            return
        }
        let accessToken = try? String.init(contentsOf: accessTokenURL, encoding: .utf8)
        completion(accessToken)
    }
}
