//
//  GigController.swift
//  Gigs
//
//  Created by Kobe McKee on 5/16/19.
//  Copyright © 2019 Kobe McKee. All rights reserved.
//

import Foundation

class GigController {
    
    var gigs: [Gig] = []
    
    var bearer: Bearer?
    
    let baseURL = URL(string: "https://lambdagigs.vapor.cloud/api")!
    
    enum HTTPMethod: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
        case delete = "DELETE"
    }
    
    enum NetworkError: Error {
        case noDataReturned
        case noBearer
        case badAuth
        case apiError
        case noDecode
        case noEncode
    }
    
    //Signing UP
    //Logging IN
    //Fetching all GIGS
    //Creating a gig & POSTING it
    
    
    
    func signUp(with username: String, password: String, completion: @escaping (Error?) -> Void) {
        
        let requestURL = baseURL
            .appendingPathComponent("users")
            .appendingPathComponent("signup")
        
        var request = URLRequest(url: requestURL)
        
        request.httpMethod = HTTPMethod.post.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let user = User(username: username, password: password)
        
        do {
            request.httpBody = try JSONEncoder().encode(user)
        } catch {
            NSLog("Error encoding user: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError())
                return
            }
            
            if let error = error {
                NSLog("Error signing up \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    
    func logIn(with username: String, password: String, completion: @escaping (Error?) -> Void) {
        
        let requestURL = baseURL
            .appendingPathComponent("users")
            .appendingPathComponent("login")
        
        var request = URLRequest(url: requestURL)
        
        request.httpMethod = HTTPMethod.post.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let user = User(username: username, password: password)
        
        do {
            request.httpBody = try JSONEncoder().encode(user)
        } catch {
            NSLog("Error encoding user: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError())
                return
            }
            
            if let error = error {
                NSLog("Error signing up \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let bearer = try decoder.decode(Bearer.self, from: data)
                self.bearer = bearer
                completion(nil)
            } catch {
                NSLog("Error decoding Bearer: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
    
    func fetchAllGigs(completion: @escaping (Result<[Gig], NetworkError>) -> Void) {
        
        guard let bearer = bearer else {
            NSLog("No bearer token available")
            completion(.failure(.noBearer))
            return
        }
        
        let requestURL = baseURL
            .appendingPathComponent("gigs")
        
        var request = URLRequest(url: requestURL)
        
        request.httpMethod = HTTPMethod.get.rawValue
        
        request.addValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                completion(.failure(.badAuth))
                return
            }
            
            if let error = error {
                NSLog("Error getting gigs: \(error)")
                completion(.failure(.apiError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noDataReturned))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                let gigs = try decoder.decode([Gig].self, from: data)
                self.gigs = gigs
                completion(.success(gigs))
            } catch {
                NSLog("Error decoding gigs: \(error)")
                completion(.failure(.noDecode))
            }
        }.resume()
    }
    
    
    
    
    
    
    func createNewGig(title: String, description: String, dueDate: Date, completion: @escaping (Error?) -> Void) {
        
        let newGig = Gig(title: title, description: description, dueDate: dueDate)
        
        guard let bearer = bearer else {
            NSLog("No bearer token available")
            completion(nil)
            return
        }
        
        let gigURL = baseURL.appendingPathComponent("gigs")
        
        var request = URLRequest(url: gigURL)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(newGig)
        } catch {
            NSLog("Error encoding gig: \(error)")
            completion(error)
            return
        }
        
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                NSLog("Error pushing gig to DB: \(error)")
                completion(error)
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                NSLog("Bad authenticator")
                completion(error)
                return
            }
            
            
            self.gigs.append(newGig)
            completion(nil)
            
        }.resume()
    }
    
 
}
