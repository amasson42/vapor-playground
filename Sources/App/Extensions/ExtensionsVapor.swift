import Vapor
import Fluent

public extension Database {

    func `enum`<E: RawRepresentable>(_ name: String, reflecting: E.Type) -> EnumBuilder
    where E.RawValue == String,
          E: CaseIterable {
        E.allCases.map(\.rawValue).reduce(self.enum(name), { $0.case($1) })
    }

}
