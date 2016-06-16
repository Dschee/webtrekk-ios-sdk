import Foundation

public struct ProductParameter: Equatable {
	internal var categories: [Int: String]
	internal var currency:   String
	internal var name:       String
	internal var price:      String
	internal var quantity:   String

	public init(categories: [Int: String] = [Int: String](), currency: String = "", name: String, price: String = "", quantity: String = "") {
		self.categories = categories
		self.currency = currency
		self.name = name
		self.price = price
		self.quantity = quantity
	}

}


public func ==(lhs: ProductParameter, rhs: ProductParameter) -> Bool {
	guard lhs.categories == rhs.categories else {
		return false
	}

	guard lhs.currency == rhs.currency else {
		return false
	}

	guard lhs.name == rhs.name else {
		return false
	}

	guard lhs.price == rhs.price else {
		return false
	}

	guard lhs.quantity == rhs.quantity else {
		return false
	}

	return true
}