//
//  File.swift
//  
//
//  Created by Macy Ngan on 4/30/21.
//

import Foundation
import Apollo

public class ClientLogger {
    public var env: ClientLogEnvironment

    public static let shared = ClientLogger()

    public init() {
        self.env = ClientLogEnvironment.init(rawValue: "Prod")!
    }

    public func logCounter(_ path: LogConfig.Interaction, attributes: [ClientLogCounterAttribute] = []) {
        let clientLogBase = ClientLogBase(id: "co.neeva.app.ios.browser", version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, environment: self.env)
        let clientLogCounter = ClientLogCounter(path: path.rawValue, attributes: attributes)
        let clientLog = ClientLog(counter: clientLogCounter)
        LogMutation(
            input: ClientLogInput(
                base: clientLogBase,
                log: [clientLog]
            )
        ).perform { result in
            switch result {
            case .failure(let error):
                print("LogMutation Error: \(error)")
            case .success:
                break
            }
        }
    }
}
