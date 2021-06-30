import Vapor
import Fluent

public extension Database {

    /// Generate a Fluent enum with the same cases as a Swift enum
    ///
    /// In this example, an enumeration `UserType` is created for our Swift code
    /// ```
    /// enum UserType: String, CaseIterable, Codable {
    ///     case admin, standard, restricted
    /// }
    /// ```
    /// We can map this exact same enumeration thanks to the free protocol `CaseIterable` to our Fluent database
    /// ```
    /// database.enum("userType", reflecting: UserType.self).create()
    /// ```
    ///
    /// - Parameters:
    ///   - name: Name of the enum type in the database
    ///   - reflecting: Type conforming to `CaseIterable` of raw type `String`
    /// - Returns: `EnumBuilder` matching the enumerated values
    func `enum`<E: RawRepresentable>(_ name: String, reflecting: E.Type) -> EnumBuilder
    where E.RawValue == String,
          E: CaseIterable {
        E.allCases.map(\.rawValue).reduce(self.enum(name), { $0.case($1) })
    }

}
