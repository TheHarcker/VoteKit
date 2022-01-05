import Foundation
public actor yesNoVote: VoteProtocol{
    public var id: UUID
    public var name: String
    public var options: [VoteOption]
    public var constituents: Set<Constituent>
    public var votes: [yesNoVoteType]
    public var genericValidators: [GenericValidator<yesNoVoteType>] = []
    public var particularValidators: [yesNoValidators] = []
    public var customData: [String : String] = [:]
    public static let typeName: String = "Yes-no"
    
    
    public init(id: UUID = UUID(), name: String, options: [VoteOption], constituents: Set<Constituent>, votes: [yesNoVoteType] = [], genericValidators: [GenericValidator<yesNoVoteType>] = [], particularValidators: [yesNoValidators] = [], customData: [String : String] = [:]){
        self.id = id
        self.name = name
        self.options = options
        self.constituents = constituents
        self.votes = votes
        self.genericValidators = genericValidators
        self.particularValidators = particularValidators
        self.customData = customData
    }
    
    public init(options: [VoteOption], constituents: Set<Constituent>, votes: [yesNoVoteType]) {
        self.votes = votes
        self.options = options
        self.constituents = constituents
        
        self.id = UUID()
        self.name = "Imported vote"
        self.genericValidators = []
    }
    
    public struct yesNoVoteType: VoteStub{
        public var constituent: Constituent
        public var values: [VoteOption: Bool]
        
        public var isBlank: Bool {values.isEmpty}
        
        public init(bareBonesVote constituent: Constituent) {
            self.constituent = constituent
            self.values = [:]
        }
        
        public init(constituent: Constituent, values: [VoteOption : Bool]) {
            self.constituent = constituent
            self.values = values
        }
    }
    
    public func count(force: Bool) async throws -> [VoteOption : (yes: UInt, no: UInt, blank: UInt)]{
        // Checks that all votes are valid
        if !force{
            try self.validateThrowing()
        }
        
        let votes = self.votes.map(\.values)
    
        return options.reduce(into: [VoteOption : (yes: UInt, no: UInt, blank: UInt)]()) { partialResult, option in
            
            let yes = UInt(votes.filter{
                $0[option] == true //Could be nil
            }.count)
            
            let no = UInt(votes.filter{
                $0[option] == false
            }.count)
            
            let blank = UInt(votes.filter{
                $0[option] == nil
            }.count)
            
            partialResult[option] = (yes: yes, no: no, blank: blank)
        }
    }
}

//CSV
extension yesNoVote.yesNoVoteType{
    
    // Format: Tiestamp (legacy), user identifier, then "1" if yes for the given option, "0" if no for the given option, "" if no vote was cast for the given option
    public static func fromCSVLine(values: [String], options: [VoteOption], constituent: Constituent) -> yesNoVote.yesNoVoteType? {
        guard values.count == options.count else{
            return nil
        }
        
        var errorFlag = false
        let mappedValued = values.map { str -> Bool? in
            switch str{
            case "0":
                return false
            case "1":
                return true
            case "":
                return nil
            default:
                errorFlag = true
                return nil
            }
        }
        guard !errorFlag else {
            return nil
        }
        
        
        let values = Dictionary(uniqueKeysWithValues: zip(options, mappedValued)).compactMapValues{$0}
        
        return self.init(constituent: constituent, values: values)
    }
    
    public func csvValueFor(option: VoteOption) -> String {
        if let val = values[option]{
            return val ? "1" : "0"
        } else{
            return ""
        }
    }
}
