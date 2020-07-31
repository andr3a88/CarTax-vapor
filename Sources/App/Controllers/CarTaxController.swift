//
//  CarTaxController.swift
//  App
//
//  Created by Andrea Stevanato on 04/12/2018.
//

import Vapor
import SwiftSoup

struct PlateParam: Content {
    var plate: String?
}

class CarTaxController: RouteCollection {

    // MARK: Properties

    let retrieveJSessionIdUrl = "https://infobollo.regione.veneto.it/tributi/tassaAuto/sta/stasiba/datiPerCalcolo.do"
    let performTaxCarUrl = "https://infobollo.regione.veneto.it/tributi/tassaAuto/sta/stasiba/eseguiCalcoloTassa.do"

    var cookies: HTTPCookies = HTTPCookies()

    // MARK: Methods

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("api", "bollo")
        routes.get(use: carTaxHandler)
    }


    func carTaxHandler(_ req: Request) throws -> EventLoopFuture<ItemResponse<CarTax>> {

        let param = try req.query.decode(PlateParam.self)
        guard let plate = param.plate else {
            return req.eventLoop.future(error: Abort(.badRequest, reason: "Missing parameter plate"))
        }
        if plate.count != 7 {
            return req.eventLoop.future(error: Abort(.badRequest, reason: "The plate may be invalid"))
        }

        let headers = HTTPHeaders([("Content-Type", "application/x-www-form-urlencoded")])

        let currentYear = Date().year
        let body = """
        modoScadenza=P&dataPagamento=31%2F12%2F\(currentYear)&\
        idCFProprietario=&cognDen=&nome=&tipoVeicolo=A&targa=\(plate)&\
        meseScadenza=&annoScadenza=&meseValid=&calcola=Calcola
        """

        return req.client.get(URI(string: retrieveJSessionIdUrl), headers: headers).flatMap { response in
            if let cookies = response.headers.setCookie, cookies.all.contains(where: { $0.key == "JSESSIONID" }) == true {
                self.cookies = cookies
            }
            return req.client.post(URI(string: self.performTaxCarUrl), headers: headers, beforeSend: { (request) in
                request.headers.cookie = self.cookies
                request.body = ByteBuffer(data: body.data(using: .utf8)!)
            }).flatMap({ (response) -> EventLoopFuture<ItemResponse<CarTax>> in
                do {
                    guard let body = try SwiftSoup.parse(response.description).body(), let carTax = self.parse(body: body) else {
                        return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Error parsing tax or due date"))
                    }
                    return req.eventLoop.makeSucceededFuture(ItemResponse(item: carTax))
                } catch {
                    return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Error parsing the page"))
                }
            })
        }
    }

    /// Parse the body page and search the tax and the due date
    ///
    /// - Parameter body: The page body
    /// - Returns: The tax car object
    private func parse(body: Element) -> CarTax? {
        let taxValue = try? body.getElementById("tassadovuta")?.nextElementSibling()?.text()
        let dueDate = try? body.getElementById("ultimoggutile")?.nextElementSibling()?.text()
        let powerKw = try? body.getElementById("potenzaeffettiva")?.nextElementSibling()?.text()
        let registrationDate = try? body.getElementById("dataimmatricolazione")?.nextElementSibling()?.text()
        let fuelType = try? body.getElementById("alimentazione")?.nextElementSibling()?.text()
        if let tax = taxValue.nilIfEmpty, let date = dueDate.nilIfEmpty, let fuelType = fuelType.nilIfEmpty,
            let powerKw = powerKw.nilIfEmpty, let registrationDate = registrationDate.nilIfEmpty {
            return CarTax(taxValue: tax,
                          dueDate: date,
                          powerKw: powerKw,
                          registrationDate: registrationDate,
                          fuelType: fuelType)
        }
        return nil
    }
}

private extension Date {

    var year: Int {
        return getComponent(.year)
    }

    var month: Int {
        return getComponent(.month)
    }

    var weekMonth: Int {
        return getComponent(.weekOfMonth)
    }

    var days: Int {
        return getComponent(.day)
    }

    var hours: Int {
        return getComponent(.hour)
    }

    var minutes: Int {
        return getComponent(.minute)
    }

    var seconds: Int {
        return getComponent(.second)
    }

    private func getComponent (_ component: Calendar.Component) -> Int {
        let calendar = Foundation.Calendar.current
        let unitFlags = Set<Calendar.Component>([component])
        let components = calendar.dateComponents(unitFlags, from: self)
        return components.value(for: component)!
    }
}

