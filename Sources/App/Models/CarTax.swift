import Vapor

struct CarTax {

    // MARK: Properties

    let taxValue: String
    let dueDate: String
    let powerKw: String
    let registrationDate: String
    let fuelType: String

    // MARK: Methods

    init(taxValue: String, dueDate: String, powerKw: String, registrationDate: String, fuelType: String) {
        self.taxValue = taxValue
        self.dueDate = dueDate
        self.powerKw = powerKw
        self.registrationDate = registrationDate
        self.fuelType = fuelType
    }
}

extension CarTax: Content { }
