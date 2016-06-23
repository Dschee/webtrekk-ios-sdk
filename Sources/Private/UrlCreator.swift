import Foundation

internal final class UrlCreator {

	internal static func createUrlFromEvent(event: TrackingEvent, serverUrl: String, trackingId: String) -> NSURLComponents? {
		guard let baseUrl = NSURLComponents(string: "\(serverUrl)/\(trackingId)/wt") else {
			return nil
		}

		var items = [NSURLQueryItem]()

		let properties = event.properties

		items.append(NSURLQueryItem(name: "eid", value: properties.everId))
		items.append(NSURLQueryItem(name: "ps", value: "\(properties.samplingRate)"))
		items.append(NSURLQueryItem(name: "mts", value: "\(Int64(properties.timestamp.timeIntervalSince1970 * 1000))"))
		items.append(NSURLQueryItem(name: "tz", value: "\(properties.timeZone.daylightSavingTimeOffset / 60 / 60)"))
		items.append(NSURLQueryItem(name: "X-WT-UA", value: properties.userAgent))

		if let firstStart = properties.isFirstAppStart where firstStart {
			items.append(NSURLQueryItem(name: "one", value: "1"))
		}

		if let ipAddress = properties.ipAddress {
			items.append(NSURLQueryItem(name: "X-WT-IP", value: ipAddress))
		}

		if let language = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String {
			items.append(NSURLQueryItem(name: "la", value: language))
		}
		if let userProperties = event.userProperties {
			items += userProperties.asQueryItems()
		}
		// FIXME: NEEED SESSION DETAILS
//		if let session = event.session { 
//			items += userProperties.asQueryItems()
//		}
		var pageName: String = ""
		switch event.kind {
		case .action(let actionEvent):
			let actionProperties = actionEvent.actionProperties
			if let details = actionProperties.details {
				items += details.map({NSURLQueryItem(name: "ck\($0.index)", value: $0.value)})
			}
			items.append(NSURLQueryItem(name: "ct", value: actionProperties.name))

			items += actionEvent.ecommerceProperties.asQueryItems()
			items += actionEvent.pageProperties.asQueryItems()
			if let name = actionEvent.pageProperties.name {
				pageName = name
			}

		case .media(let mediaEvent):
			items += mediaEvent.mediaProperties.asQueryItems(properties.timestamp)

			switch mediaEvent.kind {
			case .finish: items.append(NSURLQueryItem(name: "mk", value: "eof"))
			case .pause: items.append(NSURLQueryItem(name: "mk", value: "pause"))
			case .play: items.append(NSURLQueryItem(name: "mk", value: "play"))
			case .position: items.append(NSURLQueryItem(name: "mk", value: "pos"))
			case .seek: items.append(NSURLQueryItem(name: "mk", value: "seek"))
			case .stop: items.append(NSURLQueryItem(name: "mk", value: "stop"))
			case .custom(name: let name): items.append(NSURLQueryItem(name: "mk", value: name))
			}


			items += mediaEvent.ecommerceProperties.asQueryItems()

			items += mediaEvent.pageProperties.asQueryItems()
			if let name = mediaEvent.pageProperties.name {
				pageName = name
			}

		case .pageView(let pageViewEvent):
			items += pageViewEvent.pageProperties.asQueryItems()
			if let name = pageViewEvent.pageProperties.name {
				pageName = name
			}


			if let id = pageViewEvent.advertisementProperties.id {
				items.append(NSURLQueryItem(name: "mc", value: id))
			}
			if let details = pageViewEvent.advertisementProperties.details {
				items += details.map({NSURLQueryItem(name: "cc\($0.index)", value: $0.value)})
			}

			items += pageViewEvent.ecommerceProperties.asQueryItems()

		}
		let screenDimension = Webtrekk.screenDimensions()
		let p = "\(Webtrekk.pixelVersion),\(pageName),0,\(screenDimension.width)x\(screenDimension.height),32,0,\(Int64(properties.timestamp.timeIntervalSince1970 * 1000)),0,0,0"
		items = [NSURLQueryItem(name: "p", value: p)] + items

		items += [NSURLQueryItem(name: "eor", value: nil)]
		baseUrl.queryItems = items
		return baseUrl
	}

}


private extension EcommerceProperties {

	private func asQueryItems() ->  [NSURLQueryItem] {
		var items = [NSURLQueryItem]()
		if let currencyCode = currencyCode {
			items.append(NSURLQueryItem(name: "cr", value: currencyCode))
		}
		if let details = details {
			items += details.map({NSURLQueryItem(name: "cb\($0.index)", value: $0.value)})
		}
		if let orderNumber = orderNumber {
			items.append(NSURLQueryItem(name: "oi", value: orderNumber))
		}
		if let status = status {
			switch status {
			case .addedToBasket:
				items.append(NSURLQueryItem(name: "st", value: "add"))
			case .purchased:
				items.append(NSURLQueryItem(name: "st", value: "conf"))
			case .viewed:
				items.append(NSURLQueryItem(name: "st", value: "view"))
			}
		}
		if let totalValue = totalValue {
			items.append(NSURLQueryItem(name: "ov", value: "\(totalValue)"))
		}
		if let voucherValue = voucherValue {
			items.append(NSURLQueryItem(name: "cb563", value: "\(voucherValue)"))
		}
		return items
	}
}


private extension MediaProperties {

	private func asQueryItems(timestamp: NSDate) -> [NSURLQueryItem] {
		var items = [NSURLQueryItem]()
		if let bandwidth = bandwidth {
			items.append(NSURLQueryItem(name: "bw", value: "\(Int64(bandwidth))"))
		}
		if let groups = groups {
			items += groups.map({NSURLQueryItem(name: "mg\($0.index)", value: $0.value)})
		}
		if let duration = duration {
			items.append(NSURLQueryItem(name: "mt2", value: "\(Int64(duration))"))
		}
		else {
			items.append(NSURLQueryItem(name: "mt2", value: "\(0)"))
		}
		items.append(NSURLQueryItem(name: "mi", value: name))

		if let position = position {
			items.append(NSURLQueryItem(name: "mt1", value: "\(Int64(position))"))
		}
		else {
			items.append(NSURLQueryItem(name: "mt1", value: "\(0)"))
		}
		if let soundIsMuted = soundIsMuted {
			items.append(NSURLQueryItem(name: "mut", value: soundIsMuted ? "1" : "0"))
		}
		if let soundVolume = soundVolume {
			items.append(NSURLQueryItem(name: "mut", value: "\(Int64(soundVolume * 100))"))
		}
		items.append(NSURLQueryItem(name: "x", value: "\(Int64(timestamp.timeIntervalSince1970 * 1000))"))
		return items
	}
}


private extension PageProperties {

	private func asQueryItems() -> [NSURLQueryItem] {
		var items = [NSURLQueryItem]()
		if let details = details {
			items += details.map({NSURLQueryItem(name: "cp\($0.index)", value: $0.value)})
		}
		if let groups = groups {
			items += groups.map({NSURLQueryItem(name: "cg\($0.index)", value: $0.value)})
		}
		return items
	}
}


private extension UserProperties {

	private func asQueryItems() -> [NSURLQueryItem] {
		var items = [NSURLQueryItem]()
		if let details = details {
			items += details.map({NSURLQueryItem(name: "uc\($0.index)", value: $0.value)})
		}
		if let birthday = birthday {
			items = items.filter({$0.name != "uc707"})
			items.append(NSURLQueryItem(name: "uc707", value: birthdayFormatter.stringFromDate(birthday)))
		}
		if let city = city {
			items = items.filter({$0.name != "uc708"})
			items.append(NSURLQueryItem(name: "uc708", value: city))
		}
		if let country = country {
			items = items.filter({$0.name != "uc709"})
			items.append(NSURLQueryItem(name: "uc709", value: country))
		}
		if let emailAddress = emailAddress {
			items = items.filter({$0.name != "uc700"})
			items.append(NSURLQueryItem(name: "uc700", value: emailAddress))
		}
		if let emailReceiverId = emailReceiverId {
			items = items.filter({$0.name != "uc701"})
			items.append(NSURLQueryItem(name: "uc701", value: emailReceiverId))
		}
		if let firstName = firstName {
			items = items.filter({$0.name != "uc703"})
			items.append(NSURLQueryItem(name: "uc703", value: firstName))
		}
		if let gender = gender {
			items = items.filter({$0.name != "uc706"})
			items.append(NSURLQueryItem(name: "uc706", value: gender == UserProperties.Gender.male ? "1" :  "2"))
		}
		if let id = id {
			items.append(NSURLQueryItem(name: "cd", value: id))
		}
		if let lastName = lastName {
			items = items.filter({$0.name != "uc704"})
			items.append(NSURLQueryItem(name: "uc704", value: lastName))
		}
		if let newsletterSubscribed = newsletterSubscribed {
			items = items.filter({$0.name != "uc702"})
			items.append(NSURLQueryItem(name: "uc702", value: newsletterSubscribed ? "1" : "2"))
		}
		if let phoneNumber = phoneNumber {
			items = items.filter({$0.name != "uc705"})
			items.append(NSURLQueryItem(name: "uc705", value: phoneNumber))
		}
		if let street = street {
			items = items.filter({$0.name != "uc711"})
			items.append(NSURLQueryItem(name: "uc711", value: street))
		}
		if let streetNumber = streetNumber {
			items = items.filter({$0.name != "uc712"})
			items.append(NSURLQueryItem(name: "uc712", value: streetNumber))
		}
		if let zipCode = zipCode {
			items = items.filter({$0.name != "uc710"})
			items.append(NSURLQueryItem(name: "uc710", value: zipCode))
		}

		return items
	}


	private var birthdayFormatter: NSDateFormatter {
		get {
			let formatter = NSDateFormatter()
			formatter.dateFormat = "yyyyMMdd"
			return formatter
		}
	}
}