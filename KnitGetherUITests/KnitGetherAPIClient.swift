//
//  KnitGetherAPIClient.swift
//  KnitGetherUITests
//
//  Minimal synchronous HTTP client used by UI tests to seed server-side data
//  for screens that have no create UI of their own (e.g. the read-only
//  dictionary). Talks to the same dev server the app under test uses.
//

import Foundation

enum APITestError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}

struct KnitGetherAPIClient {
    let baseURL: URL

    init(baseURL: String = "http://127.0.0.1:3000/api/v1") {
        self.baseURL = URL(string: baseURL)!
    }

    /// Logs in with credentials already registered through the app and returns
    /// the access token so the test can act as that same user over the API.
    func login(email: String, password: String) throws -> String {
        let body = try JSONSerialization.data(
            withJSONObject: ["email": email, "password": password]
        )
        let data = try post("auth/login", body: body, token: nil)
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = json["accessToken"] as? String
        else {
            throw APITestError.message("login response missing accessToken")
        }
        return token
    }

    @discardableResult
    func createDictionaryTerm(
        token: String,
        term: String,
        fullName: String? = nil,
        description: String,
        relatedSkillAbbreviations: String = ""
    ) throws -> String {
        var payload: [String: Any] = [
            "term": term,
            "description": description,
            "relatedSkillAbbreviations": relatedSkillAbbreviations
        ]
        if let fullName {
            payload["fullName"] = fullName
        }

        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try post("dictionary-terms", body: body, token: token)
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let id = json["id"] as? String
        else {
            throw APITestError.message("dictionary create response missing id")
        }
        return id
    }

    private func post(_ path: String, body: Data, token: String?) throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        var outcome: Result<Data, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                outcome = .failure(error)
            } else if let http = response as? HTTPURLResponse,
                      !(200 ..< 300).contains(http.statusCode) {
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                outcome = .failure(APITestError.message("POST \(path) -> \(http.statusCode): \(text)"))
            } else {
                outcome = .success(data ?? Data())
            }
            semaphore.signal()
        }.resume()

        semaphore.wait()
        return try outcome!.get()
    }
}
