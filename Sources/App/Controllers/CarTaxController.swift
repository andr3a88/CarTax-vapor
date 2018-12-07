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

    func boot(router: Router) throws {
        let routes = router.grouped("api", "bollo")
        routes.get(use: carTaxHandler)
    }

    func carTaxHandler(_ req: Request) throws -> Future<ItemResponse<CarTax>> {

        let param = try req.query.decode(PlateParam.self)
        guard let plate = param.plate else {
            return req.future(error: VaporError(identifier: "plate_not_found", reason: "Missing parameter plate"))
        }
        if plate.count != 7 {
            return req.future(error: VaporError(identifier: "plate_not_valid", reason: "The plate may be invalid"))
        }

        let headers = HTTPHeaders([("Content-Type", "application/x-www-form-urlencoded")])
        let body = HTTPBody(string: "modoScadenza=P&dataPagamento=31%2F12%2F2019&idCFProprietario=&cognDen=&nome=&tipoVeicolo=A&targa=\(plate)&meseScadenza=&annoScadenza=&meseValid=&calcola=Calcola")

        return try req.client().get(retrieveJSessionIdUrl, headers: headers).flatMap { response in
            let containsCookies = response.http.cookies.all.contains { $0.key == "JSESSIONID" }
            if containsCookies {
                self.cookies = response.http.cookies
            }
            return try req.client().post(self.performTaxCarUrl, headers: headers, beforeSend: { (request) in
                request.http.cookies = self.cookies
                request.http.body = body
            }).then({ (response) -> EventLoopFuture<ItemResponse<CarTax>> in
                do {
                    guard let body = try SwiftSoup.parse(response.debugDescription).body(), let carTax = self.parse(body: body) else {
                        return response.future(error: VaporError(identifier: "parsing_data_error", reason: "Error parsing tax or due date"))
                    }
                    return response.future(ItemResponse(item: carTax))
                } catch {
                    return response.future(error: VaporError(identifier: "parsing_body_error", reason: "Error parsing the page"))
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
        if let tax = taxValue?.nilIfEmpty, let date = dueDate?.nilIfEmpty, let fuelType = fuelType?.nilIfEmpty,
            let powerKw = powerKw?.nilIfEmpty, let registrationDate = registrationDate?.nilIfEmpty {
            return CarTax(taxValue: tax,
                          dueDate: date,
                          powerKw: powerKw,
                          registrationDate: registrationDate,
                          fuelType: fuelType)
        }
        return nil
    }
}

