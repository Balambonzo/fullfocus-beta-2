//import UIKit
//import CloudKit
//import SwiftData
//
///// Ponte minimo verso UIKit, necessario solo per registrare l'app alle
///// notifiche push remote e ricevere quelle silenziose di CloudKit quando
///// un amico aggiorna il suo profilo pubblico (nuova foto/streak).
//final class AppDelegate: NSObject, UIApplicationDelegate {
//
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
//    ) -> Bool {
//        application.registerForRemoteNotifications()
//        return true
//    }
//
//    func application(
//        _ application: UIApplication,
//        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
//    ) {
//        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification,
//              let recordID = notification.recordID else {
//            completionHandler(.noData)
//            return
//        }
//
//        let friendCode = recordID.recordName
//
//        Task {
//            do {
//                guard let updated = try await CloudKitService.lookupFriend(byCode: friendCode) else {
//                    completionHandler(.noData)
//                    return
//                }
//
//                let context = ModelContext(AppModelContainer.shared)
//                let descriptor = FetchDescriptor<Friend>(
//                    predicate: #Predicate { $0.friendCode == friendCode }
//                )
//
//                if let friend = try context.fetch(descriptor).first {
//                    friend.username = updated.username
//                    friend.currentStreak = updated.currentStreak
//                    friend.bestStreak = updated.bestStreak
//                    friend.lastEntryDate = updated.lastEntryDate
//                    if let photo = updated.latestPhoto, let fileName = ImageStore.save(photo) {
//                        friend.profileImagePath = fileName
//                    }
//                    try? context.save()
//                }
//                completionHandler(.newData)
//            } catch {
//                completionHandler(.failed)
//            }
//        }
//    }
//
//    func application(
//        _ application: UIApplication,
//        didFailToRegisterForRemoteNotificationsWithError error: Error
//    ) {
//        // Sul Simulator senza push reali configurate è normale che fallisca:
//        // non blocca il resto dell'app (refresh manuale funziona comunque).
//    }
//}
