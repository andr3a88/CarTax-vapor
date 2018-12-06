import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    router.get { req in
        return "Written with Swift Vapor"
    }

    router.get("info") { req in
        return "Written with Swift Vapor"
    }

    try router.register(collection: CarTaxController())
}
