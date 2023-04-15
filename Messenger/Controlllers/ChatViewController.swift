
import UIKit
import MessageKit
import InputBarAccessoryView

struct Message : MessageType{
   public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
    
    
}

extension MessageKind {
    var messageKindString : String {
        switch self {
            
        case .text(_):
            return "texr"
        case .attributedText(_):
            return "attribute   "

        case .photo(_):
            return "photo"

        case .video(_):
            return "video"

        case .location(_):
            return "location"

        case .emoji(_):
            return "emoji"

        case .audio(_):
            return "audio"

        case .contact(_):
            return "contact"

        case .linkPreview(_):
            return "link"

        case .custom(_):
            return "custom"

        }
    }
}


struct Sender : SenderType {
    public var photoURL :  String
    public var senderId: String
    public var displayName: String
    
    
}

class ChatViewController: MessagesViewController {
    
    
    public static let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public let otherUserEmail : String
    public var isNewConversation = false

    private var messages = [Message]()
    private var  selfSender : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
       return Sender(photoURL: "",
               senderId: email,
               displayName: "Hatem Ganash")}
    
    init(with email: String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
}
extension ChatViewController : InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: " ").isEmpty,
        let selfSender = self.selfSender,
              let messageId = creatMessageId()
        else {
            return
        }
        print("sending \(text)")
        
        if isNewConversation {
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.creatNewConversation(with: otherUserEmail , firstMessage: message, completion: { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
                
            })
            
        }
        else {
            
        }
    }
    private func creatMessageId() -> String?{
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("created message id :\(newIdentifier)")
        return newIdentifier
    }
    
}
extension ChatViewController : MessagesDataSource , MessagesLayoutDelegate , MessagesDisplayDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
       // fetalError("Self Sender")
        return Sender(photoURL: "", senderId: "12", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
     
}
