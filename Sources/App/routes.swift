import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    app.get { req in
        return "Written with Swift Vapor"
    }

    app.get("info") { req in
        return "Written with Swift Vapor"
    }

    try app.register(collection: CarTaxController())
}
