import Foundation
public typealias ConstituentIdentifier = String


/// The description of a voter in a vote
public struct Constituent: Hashable, Codable, Sendable{
	public var name: String?
	public var identifier: ConstituentIdentifier
	
	public var tag: String?
	
	public init(name: String? = nil, identifier: ConstituentIdentifier, tag: String? = nil){
		self.name = name
		self.identifier = identifier
		self.tag = tag
	}
	
	/// Retrieves a screen name for the user, primarily the name proporty, if it is nil its identifier will be used
	public func getNameOrId() -> String {
		return name ?? identifier
	}
}

// Primarily used for simply creating a constituent in tests
extension Constituent: ExpressibleByStringLiteral{
	public init(stringLiteral value: ConstituentIdentifier){
		self.init(identifier: value)
	}
}

