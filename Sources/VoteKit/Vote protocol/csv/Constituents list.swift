//MARK: Export
// Allows for the conversion of any kind of sequence containing constituents to be converted into csv
extension Sequence where Element == Constituent{
	/// Creates a string representation of a CSV file containing the name and userid for all constituents
	/// - Returns: A string containing a CSV representation of the constituents
	public func toCSV(config: CSVConfiguration) -> String{
		var csv: String
		let showTags = config.specialKeys["constituents-export show-tags"] == "1"
		
		if let header = config.specialKeys["constituents-export header"]{
			csv = header
		} else if showTags{
			csv = "Name,Identifier,Tag"
		} else {
			csv = "Name,Identifier"
		}
		
		
		let voters = self.sorted { $0.identifier < $1.identifier}
		
		for voter in voters {
			csv += "\n"
			
			let name = voter.name ?? voter.identifier
			if showTags{
				let tag = voter.tag ?? ""
				csv += "\(name),\(voter.identifier),\(tag)"
			} else {
				csv += "\(name),\(voter.identifier)"
			}
		}
		return csv
	}
}

//MARK: Import
/// Creates an array of constituents from a CSV file
public func constituentsListFromCSV(file: String, config: CSVConfiguration? = nil, maxNameLength: Int) throws -> [Constituent] {
	guard !file.contains(";"), !file.contains("\t") else {
		throw DecodeConstituentError.invalidCSV
	}
	
	var individualConstituentLines = file.split(whereSeparator: \.isNewline)
	
	// There has to be a limit
	if individualConstituentLines.count > 10_000 {
		throw DecodeConstituentError.nameTooLong
	}
	
	guard let header = individualConstituentLines.first else {
		throw DecodeConstituentError.invalidCSV
	}
	
	// Verifies header is present
	let hasTags: Bool
	if header == "Name,Identifier,Tag"{
		hasTags = true
	} else if header == "Name,Identifier" {
		hasTags = false
	} else if config?.specialKeys["constituents-export header"] != nil && header == config!.specialKeys["constituents-export header"]!{
		hasTags = false
	} else {
		throw DecodeConstituentError.invalidCSV
	}
	
	//Removes header
	individualConstituentLines = Array(individualConstituentLines.dropFirst())
	
	return try individualConstituentLines.map{ row -> Constituent in
		let s = row.split(separator:",", omittingEmptySubsequences: false)
		guard hasTags && s.count == 3 || !hasTags && s.count == 2 else {
			throw DecodeConstituentError.invalidCSV
		}
		
		let rawName = String(s[0]).trimmingCharacters(in: .whitespacesAndNewlines)
		let rawIdentifier = String(s[1]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		
		let tag: String?
		if hasTags{
			let rawTag = String(s[2]).trimmingCharacters(in: .whitespacesAndNewlines)
			
			// To enable sorting of external and internal tags
			guard rawTag.first != "-", rawTag.count <= maxNameLength else {
				throw DecodeConstituentError.invalidTag
			}
			tag = rawTag.isEmpty ? nil : rawTag
		} else {
			tag = nil
		}
		
		if rawIdentifier.isEmpty{
			throw DecodeConstituentError.invalidIdentifier
		}
		
		guard rawIdentifier.count <= maxNameLength, rawName.count <= maxNameLength else {
			throw DecodeConstituentError.nameTooLong
		}
		
		let identifier: String = rawIdentifier
		let name: String? = (rawName.isEmpty || rawName == rawIdentifier) ? nil : rawName
		
		return Constituent(name: name, identifier: identifier, tag: tag)
		
	}
}

public enum DecodeConstituentError: Error{
	case invalidIdentifier, nameTooLong, invalidCSV, invalidTag
}