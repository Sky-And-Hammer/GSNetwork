//
//  Protocol.swift
//  GSNetowrk
//
//  Created by 孟钰丰 on 2017/12/23.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Alamofire
import HandyJSON

public protocol APIErrorRetable: HandyJSON {
    var code: Int { get set }
    var msg: String { get set }
}

public protocol APIRetable: HandyJSON {
    associatedtype T: HandyJSON
    associatedtype U: APIErrorRetable
    
    var error: U? { get set }
}

public enum HTTPMethod {
    case get, post, head, put, patch, delete, form
    
    func translate() -> Alamofire.HTTPMethod {
        switch self {
        case .get:
            return Alamofire.HTTPMethod.get
        case .post:
            return Alamofire.HTTPMethod.post
        case .head:
            return Alamofire.HTTPMethod.head
        case .put:
            return Alamofire.HTTPMethod.put
        case .patch:
            return Alamofire.HTTPMethod.patch
        case .delete:
            return Alamofire.HTTPMethod.delete
        case .form:
            return Alamofire.HTTPMethod.get
        }
    }
}

/// APIRoute

public typealias APIFailureClosure = (GSNetworkError) -> Void
public protocol APIRoute {
    
    /// URL
    var uri: String { get }
    
    /// 请求参数
    var parameters: [String : Any] { get }
    
    /// 请求方式
    var method: HTTPMethod { get }
    
    // MARK: - 以下有默认实现
    
    /// 请求 host
    ///
    /// - Returns: 自定义请求 host
    func customHost() -> String?
    
    /// 请求失败 closure
    func failure() -> APIFailureClosure
}

// MARK: - 默认实现方式

public extension APIRoute {
    
    func requestForUI(isBegin: Bool) {}
    
    func customHost() -> String? { return nil }
    
    func failure() -> APIFailureClosure {
        return Network.config.failureClosure ?? { _ in }
    }
}

public struct ApiPage {
    
    public var offset: Int = 1
    public var pageSize: Int = 10
    
    public init() { }
    
    public func parameters(p: [String: Any]) -> [String: Any] {
        var p = p
        p["page"] = offset
        p["pagesize"] = pageSize
        return p
    }
}
