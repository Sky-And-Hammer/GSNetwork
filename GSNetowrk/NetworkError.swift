//
//  NetworkError.swift
//  GSNetowrk
//
//  Created by 孟钰丰 on 2017/12/23.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSStability

public enum GSNetworkError: GSError {
    
    public enum ServerErrorReason: GSErrorReason {
        
        case responseError(code: Int, msg: String)
        case noNetworkError
        
        public var reasonDescription: String {
            switch self {
            case .responseError(let code, let msg):
                return "\(code): \(msg)"
            case .noNetworkError:
                return "无网络连接"
            }
        }
    }
    
    public enum InnerErrorReason: GSErrorReason {
        
        case oauthExpireOrInvalid
        case otherError
        
        public var reasonDescription: String {
            switch self {
            case .oauthExpireOrInvalid:
                return "oauth 过期或者失效"
            case .otherError:
                return " 非业务错误，不向上抛出，包括泛型转换错误和其他错误"
            }
        }
    }
    
    case serverError(reason:ServerErrorReason)
    case innerError(reason: InnerErrorReason)
}
