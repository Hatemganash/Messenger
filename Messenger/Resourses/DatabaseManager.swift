
import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress : String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}
// Accont Management

extension DatabaseManager {
    public func userExist(with email : String ,
                          completion : @escaping ((Bool)->Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            
            guard  snapshot.value as? String != nil
            else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    public func insertUser (with user: ChatAppUser , completion : @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name":user.firstName,
            "last_name" :user.lastName
        ] , withCompletionBlock: {error , _ in
            guard error == nil else{
                print("Failed to write to database")
                completion (false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String:String]]{
                    //append to user dectionary
                    let newElement = ["name" : user.firstName + " " + user.lastName,
                                      "email" : user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection , withCompletionBlock: { error , _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion (true)
                    })
                    
                }
                else {
                    // creat that array
                    let newCollection : [[String:String]] = [
                        ["name" : user.firstName + " " + user.lastName,
                         "email" : user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection , withCompletionBlock: { error , _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion (true)
                    })
                }
            })
            
            completion (true)
        })
    }
    
    public func getAllUsers(completion : @escaping(Result<[[String:String]], Error>)-> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion (.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    public enum DatabaseError : Error {
        case failedToFetch
    }
}

//conversations

extension DatabaseManager {
    public func creatNewConversation(with otherUserEmail:String, firstMessage : Message, completion : @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with:  { snapshot in
            guard var userNode = snapshot.value as? [String : Any] else {
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateSttring = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData:[String : Any] = [ "id": conversationId,
                                                       "other_user_email": otherUserEmail ,
                                                       "latest_message": [
                                                        "date" : dateSttring ,
                                                        "message":message,
                                                        "Is_read" : false
                                                       ]
            ]
            if var conversations = userNode["conversations"] as? [[String : Any ]]{
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error , _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, completion: completion)                })
            }
            else {
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode, withCompletionBlock: { [weak self] error , _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                    
                })
            }
        })
    }
    
    private func finishCreatingConversation(conversationId : String , firstMessage : Message , completion : @escaping (Bool) -> Void ){
        //        "id": String,
        //        "type":text,photo,video ,
        //        "content" : String,
        //        "date":Date(),
        //        "sender_email":String,
        //        "isRead:": true/false"
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage :[String : Any] = [
            "id": firstMessage.messageId ,
            "type": firstMessage.kind.messageKindString,
            "content":message,
            "date":dateString,
            "sender_email":currentUserEmail,
            "is_read": false
            
        ]
        
        let value : [String : Any] = [
            "messages" : [
                collectionMessage
            ]
            
        ]
        print("adding  convo : \(conversationId)")
        
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error,_ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    public func getAllConversation(for email:String,completion : @escaping(Result<String,Error>) -> Void){
        
    }
    
    public func getAllMessagesForConversation(with id : String , completion : @escaping (Result<String , Error>) -> Void){
        
    }
    
    public func sendMessage(to conversation : String , message : Message , completion : @escaping(Bool) -> Void){
        
        
    }
}







struct ChatAppUser {
    let firstName : String
    let lastName : String
    let emailAddress : String
    
    var safeEmail : String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePicUFileName : String {
        return "\(safeEmail)_profile_pic.png"
    }
}

