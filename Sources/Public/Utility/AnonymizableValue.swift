//The MIT License (MIT)
//
//Copyright (c) 2016 Webtrekk GmbH
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
//"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish,
//distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject
//to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Created by Widgetlabs
//


public enum AnonymizableValue<HashedType> {
    case plain(HashedType)
    case hashed(md5: String?, sha256: String?)
    
    func toJSONObj() -> [String: Any?] {
        
        switch self {
        case .plain(let plain):
            
            if let string = plain as? String {
                return ["plain": string]
            } else if let address = plain as? CrossDeviceProperties.Address {
                return ["plain":address.toJSONObj()]
            } else {
                logError("Cross device bridge information address couldn't be serialized")
                return [:]
            }
            
        case .hashed(let md5, let sha256):
            return ["md5":md5, "sha256":sha256]
        }
    }
}
