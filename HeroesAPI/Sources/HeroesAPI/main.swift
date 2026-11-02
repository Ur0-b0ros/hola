
import Foundation
import Swifter

struct Hero: Codable {
    var id: Int
    var nombre: String
    var superpoder: String
    var identidadSecreta: String
}

struct HeroInput: Codable {
    var nombre: String
    var superpoder: String
    var identidadSecreta: String
}

let server = HttpServer()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

var heroes: [Hero] = [
    Hero(
        id: 1,
        nombre: "Spider-Man",
        superpoder: "Trepar paredes",
        identidadSecreta: "Peter Parker"
    ),
    Hero(
        id: 2,
        nombre: "Superman",
        superpoder: "Volar y superfuerza",
        identidadSecreta: "Clark Kent"
    )
]

var siguienteID = 3

func respuestaJSON<T: Encodable>(
    _ valor: T,
    status: Int = 200
) -> HttpResponse {
    do {
        let data = try encoder.encode(valor)
        let json = String(
            decoding: data,
            as: UTF8.self
        )

        return HttpResponse.raw(
            status,
            "OK",
            ["Content-Type": "application/json; charset=utf-8"],
            { writer in
                try writer.write([UInt8](json.utf8))
            }
        )
    } catch {
        return .internalServerError
    }
}

func errorJSON(
    _ mensaje: String,
    status: Int
) -> HttpResponse {
    return respuestaJSON(
        ["error": mensaje],
        status: status
    )
}

// GET /heroes
server["/heroes"] = { request in
    if request.method == "GET" {
        return respuestaJSON(heroes)
    }

    // POST /heroes
    if request.method == "POST" {
        do {
            let data = Data(request.body)
            let nuevo = try JSONDecoder().decode(
                HeroInput.self,
                from: data
            )

            guard !nuevo.nombre.isEmpty,
                  !nuevo.superpoder.isEmpty,
                  !nuevo.identidadSecreta.isEmpty else {
                return errorJSON(
                    "Todos los campos son obligatorios",
                    status: 400
                )
            }

            let heroe = Hero(
                id: siguienteID,
                nombre: nuevo.nombre,
                superpoder: nuevo.superpoder,
                identidadSecreta: nuevo.identidadSecreta
            )

            siguienteID += 1
            heroes.append(heroe)

            return respuestaJSON(heroe, status: 201)
        } catch {
            return errorJSON(
                "El cuerpo debe contener un JSON válido",
                status: 400
            )
        }
    }

    return errorJSON("Método no permitido", status: 405)
}

// GET /heroes/{id}
server["/heroes/:id"] = { request in
    guard let idTexto = request.params[":id"],
          let id = Int(idTexto) else {
        print("Parámetros recibidos: \(request.params)")
        return errorJSON("ID inválido", status: 400)
    }

    guard let indice = heroes.firstIndex(
        where: { $0.id == id }
    ) else {
        return errorJSON("Héroe no encontrado", status: 404)
    }

    if request.method == "GET" {
        return respuestaJSON(heroes[indice])
    }

    // PUT /heroes/{id}
    if request.method == "PUT" {
        do {
            let nuevo = try JSONDecoder().decode(
                HeroInput.self,
                from: Data(request.body)
            )

            guard !nuevo.nombre.isEmpty,
                  !nuevo.superpoder.isEmpty,
                  !nuevo.identidadSecreta.isEmpty else {
                return errorJSON(
                    "Todos los campos son obligatorios",
                    status: 400
                )
            }

            heroes[indice].nombre = nuevo.nombre
            heroes[indice].superpoder = nuevo.superpoder
            heroes[indice].identidadSecreta =
                nuevo.identidadSecreta

            return respuestaJSON(heroes[indice])
        } catch {
            return errorJSON(
                "El cuerpo debe contener un JSON válido",
                status: 400
            )
        }
    }

    // DELETE /heroes/{id}
    if request.method == "DELETE" {
        let eliminado = heroes.remove(at: indice)
        return respuestaJSON(eliminado)
    }

    return errorJSON("Método no permitido", status: 405)
}

do {
    try server.start(8080, forceIPv4: true)
    print("API de héroes iniciada en http://localhost:8080")
    print("Presioná Ctrl+C para detener el servidor")
    while true {
        Thread.sleep(forTimeInterval: 3600)
    }
} catch {
    print("No se pudo iniciar el servidor: \(error)")
}
