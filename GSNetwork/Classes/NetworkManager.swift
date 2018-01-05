//
//  NetworkManager.swift
//  GSNetowrk
//
//  Created by 孟钰丰 on 2017/12/23.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSStability
import Alamofire
import GSFoundation

public let Network = GSNetwork.default

public extension Notification.Name.gs {
    
    public struct NetworkState {
        public static let networkStateChange = Notification.Name(notificationPrefix + ".NetworkState" + ".networkStateChange")
    }
}

public class NetworkConfig {
    
    // API 的 host
    public var host = ""
    public var failureClosure: APIFailureClosure?
    
    /// 请求中额外需要的默认参数配置
    public var extendParameter: ((Parameters?) -> Parameters?) = { return $0 }
    
    public var adapter: RequestAdapter? = nil
    public var retrier: RequestRetrier? = nil
    
    public init() {}
    
    public func then(_ closure:(NetworkConfig) -> Void) -> Self {
        closure(self)
        return self
    }
}

public final class GSNetwork {
    
    /// 超时时长
    public static var timeout = 10.0
    
    internal var config = NetworkConfig() {
        didSet {
            session.adapter = config.adapter
            session.retrier = config.retrier
        }
    }
    
    public var isReachable: Bool {
        return networkState != .notReachable && networkState != .unknown
    }
    
    public static let `default`: GSNetwork = {
        return GSNetwork()
    }()
    
    internal var session: SessionManager {
        return SessionManager.default
    }
    
    internal var reachabilityManager: NetworkReachabilityManager?
    internal var networkState: NetworkReachabilityManager.NetworkReachabilityStatus = .unknown {
        didSet {
            switch networkState {
            case .notReachable, .unknown:
                NotificationCenter.default.post(name: NSNotification.Name.gs.NetworkState.networkStateChange, object: false, userInfo: nil)
            case .reachable(_) :
                NotificationCenter.default.post(name: NSNotification.Name.gs.NetworkState.networkStateChange, object: true, userInfo: nil)
            }
        }
    }
    
    
    private init() {}
    
    /// 配置参数
    ///
    /// - Parameter config: 配置对象
    public func config(config: NetworkConfig) {
        self.config = config
        self.reachabilityManager = NetworkReachabilityManager(host: config.host.components(separatedBy: "://").last ?? "")
        self.reachabilityManager?.listener = {
            self.networkState = $0
        }
        self.reachabilityManager?.startListening()
    }
    
    deinit {
        self.reachabilityManager?.stopListening()
    }
}

// MARK: - Request

extension GSNetwork {
    
//    /// API 调用
//    ///
//    /// - Parameters:
//    ///   - route: route
//    ///   - success: success closure
//    ///   - failure: failure closure
//    public func route<T: HandyJSON>(_ route: APIRoute, success: @escaping (T) -> Void, failure: @escaping APIFailureClosure) {
//
//
//        innerRoute(route, success: { (rs: APIRet<T>) in
//            success(rs.data)
//        }, failure: failure)
//    }
//
//    /// API 调用
//    ///
//    /// - Parameters:
//    ///   - route: route
//    ///   - success: success closure
//    ///   - failure: failure closure
//    public func route<T: HandyJSON>(_ route: APIRoute, success: @escaping ([T]) -> Void, failure: @escaping APIFailureClosure) {
//        innerRoute(route, success: { (rs: APIListRet<T>) in
//            success(rs.data)
//        }, failure: failure)
//    }
    
    /// 内部 API 调用
    ///
    /// - Parameters:
    ///   - route: route
    ///   - success: success closure
    ///   - failure: failure closure
    public func route<T: APIRetable>(_ route: APIRoute, success: @escaping ((T, URLRequest?, HTTPURLResponse?) -> Void), failure: @escaping APIFailureClosure) {
//        guard isReachable else {
//            // 无网络的错误
//            // 只尝试给 上面一层调用方中的错误处理 closure 进行处理 因为一般这里包括了UI的逻辑
//            Async.main { failure(GSNetworkError.serverError(reason: .noNetworkError)) }
//            return
//        }
        
        let url = (route.customHost() ?? config.host) + route.uri
        let request = session.request(url, method: route.method.translate(), parameters: config.extendParameter(route.parameters), encoding: URLEncoding.default)
        
        print("***\(request.description)")
        
        request.responseModel { (rs: DataResponse<T?>) in
            if let result = rs.result.value, let trueResult = result {
                if let error = trueResult.error {
                    let error = GSNetworkError.serverError(reason: .responseError(code: error.code, msg: error.msg))
                    // 此处区分了 route 本身的错误回掉和调用网络请求时的错误回调
                    // 暂定的逻辑举例来说 route 失败后会清除存储数据。 而接口调用失败会更新页面, 展示错误信息的 hud 等。。。
                    Async.main {
                        route.failure()(error)
                        failure(error)
                    }
                } else {
                    Async.main { success(trueResult, rs.request, rs.response) }
                }
                
//                let headerFields = response.response?.allHeaderFields as! [String: String]
//                let url = response.request?.url
//                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
//                var cookieArray = [ [HTTPCookiePropertyKey : Any ] ]()
//                for cookie in cookies {
//                    cookieArray.append(cookie.properties!)
//                }
//
//                作者：lesliefang
//                链接：https://www.jianshu.com/p/2bb8f8e428b5
//                來源：简书
//                著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
                
//                if trueResult.isSuccess {
//                    Async.main { success(trueResult) }
//                } else {
//                    let error = GSNetworkError.serverError(reason: .responseError(code: trueResult.error?.code, msg: trueResult.error?.msg))
//                    // 此处区分了 route 本身的错误回掉和调用网络请求时的错误回调
//                    // 暂定的逻辑举例来说 route 失败后会清除存储数据。 而接口调用失败会更新页面, 展示错误信息的 hud 等。。。
//                    Async.main {
//                        route.failure()(error)
//                        failure(error)
//                    }
//
//                }
                
//                if trueResult.code == 0 {
//                    Async.main { success(trueResult) }
//                } else {
//                    let error = GSNetworkError.serverError(reason: .responseError(code: trueResult.code, msg: trueResult.msg))
//                    // 此处区分了 route 本身的错误回掉和调用网络请求时的错误回调
//                    // 暂定的逻辑举例来说 route 失败后会清除存储数据。 而接口调用失败会更新页面, 展示错误信息的 hud 等。。。
//                    Async.main {
//                        route.failure()(error)
//                        failure(error)
//                    }
//                }
            } else {
                // 非正常错误，不向上抛出，包括泛型转换错误和网络请求失败
                // 只尝试给 上面一层调用方中的错误处理 closure 进行处理 因为一般这里包括了UI的逻辑
                Async.main { failure(GSNetworkError.innerError(reason: .otherError)) }
            }
        }
    }
}

// MARK: - Alamofire & HandyJSON Extension

extension Request {
    
    public static func serializeResponseModel<T: GSJSON>(
        options: JSONSerialization.ReadingOptions,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?)
        -> Result<T?> {
            guard error == nil else { return .failure(error!) }
            // alamofire private let emptyDataStatusCodes: Set<Int> = [204, 205]
            if let response = response, [204, 205].contains(response.statusCode) { return .success(nil) }
            
            guard let validData = data, validData.count > 0 else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
            }
            
            if let jsonString = String(data: validData, encoding: .utf8) {
                return .success(T.json(from: jsonString))
            } else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }
    }
}
extension DataRequest {
    
    public static func modelResponseSerializer<T: GSJSON>(
        options: JSONSerialization.ReadingOptions = .allowFragments)
        -> DataResponseSerializer<T?> {
            return DataResponseSerializer { _, response, data, error in
                return Request.serializeResponseModel(options: options, response: response, data: data, error: error)
            }
    }
    
    @discardableResult
    public func responseModel<T: GSJSON>(
        queue: DispatchQueue? = nil,
        options: JSONSerialization.ReadingOptions = .allowFragments,
        completionHandler: @escaping (DataResponse<T?>) -> Void)
        -> Self {
            return response(
                queue: queue,
                responseSerializer: DataRequest.modelResponseSerializer(options: options),
                completionHandler: completionHandler)
    }
    
//    @discardableResult
//    public func validate<S: Sequence>(_ apiAllow: S) -> Self where S.Iterator.Element == Int {
//        return validate { (_, response, data)  in
//            guard let url = response.url?.absoluteString, url.hasPrefix(Network.config.host) else {
//                return .success
//            }
//            
//            guard let validData = data, validData.count > 0 else { return .success }
//            guard let json = String(data: validData, encoding: .utf8) else { return .success }
//            guard let ret = JSONDeserializer<APIRetCheck>.deserializeFrom(json: json) else { return .success }
//            if apiAllow.contains(ret.code) {
//                return .failure(GSNetworkError.innerError(reason: GSNetworkError.InnerErrorReason.oauthExpireOrInvalid))
//            } else {
//                return .success
//            }
//        }
//    }
}
