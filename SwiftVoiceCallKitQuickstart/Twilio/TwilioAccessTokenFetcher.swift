//
//  TwilioAccessTokenFetcher.swift
//  TwilioCallKitQuickstart
//

import Foundation

class TwilioAccessTokenFetcher: NSObject {
    
    // TODO: Replace this url by your
    private let baseURLString = "https://accesstoken.com"
    // If your token server is written in PHP, accessTokenEndpoint needs .php extension at the end. For example : /accessToken.php
    private let accessTokenEndpoint = "/accessToken"
    private let identity = "alice"
    
    func fetchAccessToken(_ completion: (String?) -> Void) {
        let endpointWithIdentity = String(format: "%@?identity=%@", accessTokenEndpoint, identity)
        guard let accessTokenURL = URL(string: baseURLString + endpointWithIdentity) else {
            completion(nil)
            return
        }
        var accessToken = try? String.init(contentsOf: accessTokenURL, encoding: .utf8)
        
        // !!!Fake access token:
        accessToken = "N3BF5Gqg90is9yBCZBIHnMg1pyPvV0J0ANZkz2rjZOU"
        
        completion(accessToken)
    }
}
