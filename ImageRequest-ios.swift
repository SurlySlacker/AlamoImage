//
//  ImageRequest.swift
//  AlamoImage
//
//  Created by Guillermo Chiacchio on 6/4/15.
//
//

import Alamofire
import Foundation

#if os(iOS)

/**
Alamofire.Request extension to support a handler for images. iOS Only
*/
extension Request {

    class func imageResponseSerializer() -> ResponseSerializer<UIImage, NSError> {
        return ResponseSerializer { request, response, data, error in
            guard error == nil else {return .Failure(error!)}
            guard let validData = data else {
                let failureReason = "String could not be serialized because input data was nil."
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            guard let image = UIImage(data: validData, scale: UIScreen.mainScreen().scale) else {
                let failureReason = "Data could not be serialized into an image."
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            return .Success(image)
        }
    }

    /**
    Adds a handler to be called once the request has finished.
    
    :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the UIImage object, if one could be created from the URL response and data, and any error produced while creating the UIImage object.
    
    :returns: The request.
    */
    public func responseImage(completionHandler: Response<UIImage, NSError> -> Void) -> Self{
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
}

/**
UIImage extension to support and handle the request of a remote image, to be downloaded. iOS Only.
*/
extension UIImage {
    /**
    Creates a request using `Alamofire`, and returns the image into the success closure. This method automatically adds and retrieves the image to/from the global `AlamoImage.imageCache` cache instance if any.
    If you just want to get the image, without taking care of errors or requests, look for the shorter version
    
    :param: URLStringConv The URL for the image.
    :param: success The code to be executed if the request finishes successfully.
    :param: failure The code to be executed if the request finishes with some error.
    :returns: The request created or .None if was retrieved from the global `AlamoImage.imageCache` cache instance.
    */
    public static func requestImage(URLStringConv: URLStringConvertible,
        success: (UIImage) -> Void,
        failure: (NSError) -> Void = { (_) in }
        ) -> Request?
    {
        if let cachedImage = imageCache?.objectForKey(URLStringConv.URLString) as? UIImage {
            success(cachedImage)
            return .None
        } else {
            return Alamofire.request(.GET, URLStringConv).validate().responseImage()
                {
                    (response: Response<UIImage, NSError>) in
                    switch response.result{
                    case .Success(let image):
                        imageCache?.setObject(image, forKey: URLStringConv.URLString)
                        success(image)
                        break
                    case .Failure(let error):
                        failure(error)
                        break
                    }
            }
        }
    }

    /**
    Creates a request using `Alamofire`, and returns the image into the success closure. This method automatically adds and retrieves the image to/from the global `AlamoImage.imageCache` cache instance if any.
    
    Example:
    
    `UIImage.requestImage(photoUrl){self.photo = $0}`
    
    
    :param: URLStringConv The URL for the image.
    :param: success The code to be executed if the request finishes successfully.
    :returns: The request created or .None if was retrieved from the global `AlamoImage.imageCache` cache instance.
    */
    public static func requestImage(URLStringConv: URLStringConvertible,
        success: (UIImage?) -> Void) -> Request?
    {
        return requestImage(URLStringConv, success: { image in success(image)}, failure: {_ in})
    }
}

#endif
