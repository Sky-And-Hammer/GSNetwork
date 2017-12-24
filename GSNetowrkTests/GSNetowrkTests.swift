//
//  GSNetowrkTests.swift
//  GSNetowrkTests
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import XCTest
import HandyJSON
import Alamofire
@testable import GSNetowrk

enum Route: APIRoute {
    var uri: String {
        switch self {
        case .r_listBoard: return "/board.act?cmd=listBoard"
        case .r_login: return "/user.act?cmd=login"
        }
    }
    
    var parameters: [String : Any] {
        switch self {
        case .r_listBoard: return ["num":1, "code":"cn"]
        case .r_login: return [:]
        }
    }
    
    var method: GSNetowrk.HTTPMethod {
        return .get
    }
    
    
    case r_listBoard
    case r_login
}

struct A: HandyJSON {
    var id = 0
    var title = ""
}

struct APIRetStruct<S: HandyJSON>: APIRetable {
    typealias U = AError
    
    
    typealias T = S
    
    var data: S! = nil
    var error: U? = nil
}

struct APIRetListStruct<S: HandyJSON>: APIRetable {
    
    typealias T = S
    typealias U = AError
    
    var data: [S] = []
    var error: AError? = nil
}

struct AError: APIErrorRetable  {
    var msg: String = ""
    var code: Int = 0
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<< msg <-- "message"
    }
}

struct adapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        
        print("1")
        return urlRequest
        
        
    }
}

class GSNetowrkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        Network.config(config: NetworkConfig.init().then {
            $0.host = "https://mail.trzy001.com/bsts"
            $0.adapter = adapter.init()
//            $0.APIRetStruct = APIRetStruct.self
//            $0.APIRetListStruct = APIRetListStruct.self
            $0.failureClosure = { err in
                print(err.localizedDescription)
            }
            
        })
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testForNormalApi() {
        let expectation = self.expectation(description: "request should eventually fail")
        Network.route(Route.r_listBoard, success: { (result: APIRetListStruct<A>, _, _) in
            expectation.fulfill()
        }, failure: { (_) in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: 360, handler: nil)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


