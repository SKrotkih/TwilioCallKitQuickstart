//
//  TwilioAccessTokenFetcher.swift
//  TwilioVoicePackage
//
import Foundation

// TODO: Implement this class for your Twilio app server before using the Twilio features
// For example, the fetchAccessToken() should be async throws method and use it somwhere in init app section
class TwilioAccessTokenFetcher: NSObject {
    static func fetchAccessToken() -> String {
        enum TokenError: Error {
            case wrongUrl
            case wrongToken
            
            func message() -> String {
                switch self {
                case .wrongUrl:
                    return "TwilioAccessTokenFetcher: Wrong URL"
                case .wrongToken:
                    return "TwilioAccessTokenFetcher: Wrong token"
                }
            }
        }
        let baseURLString = "https://accesstoken.com"
        // If your token server is written in PHP, accessTokenEndpoint needs .php
        // extension at the end. For example : /accessToken.php
        let accessTokenEndpoint = "/accessToken"
        let identity = "alice"
        let endpointWithIdentity = String(format: "%@?identity=%@", accessTokenEndpoint, identity)
        
        do {
            if let accessTokenURL = URL(string: baseURLString + endpointWithIdentity) {
                if let accessToken = try? String.init(contentsOf: accessTokenURL, encoding: .utf8) {
                    return accessToken
                } else {
                    throw TokenError.wrongToken
                }
            } else{
                throw TokenError.wrongUrl
            }
        } catch {
            if let error = error as? TokenError {
                print(error.message)
            }
            // !!!Fake access token. Don't use it in production
            return "N3BF5Gqg90is9yBCZBIHnMg1pyPvV0J0ANZkz2rjZOU"
        }
    }
}
