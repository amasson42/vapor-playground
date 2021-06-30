import Vapor
import Fluent

final class Acronym: Model {
    static let schema = v100.schema
    
    @ID
    var id: UUID?

    @Field(key: v100.short)
    var short: String
    
    @Field(key: v100.long)
    var long: String
    
    @Parent(key: v100.userID)
    var user: User
    
    @Siblings(through: AcronymCategoryPivot.self,
              from: \.$acronym,
              to: \.$category)
    var categories: [Category]
    
    @Timestamp(key: v120.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: v120.updatedAt, on: .update)
    var updatedAt: Date?

    init() {}
    
    init(id: UUID? = nil, short: String, long: String, userID: User.IDValue) {
        self.id = id
        self.short = short
        self.long = long
        self.$user.id = userID
    }
    
}

// TODO: Find why it is not being executed
extension Acronym: Content {
    func beforeEncode() throws {
        if self.short.lowercased().contains(where: { !self.long.lowercased().contains($0) }) {
            print("\(self.short) cannot be an acronym of \(self.long)")
            throw Abort(.badRequest, reason: "\(self.short) cannot be an acronym of \(self.long)")
        } else {
            print("encoding: \(self.short): \(self.long)")
        }
        // Before Encoding to make sure the data are correct
    }
    
    func afterDecode() throws {
        if self.short.lowercased().contains(where: { !self.long.lowercased().contains($0) }) {
            print("\(self.short) cannot be an acronym of \(self.long)")
            throw Abort(.badRequest, reason: "\(self.short) cannot be an acronym of \(self.long)")
        } else {
            print("decoded: \(self.short): \(self.long)")
        }
        // After Decoding
    }
}
