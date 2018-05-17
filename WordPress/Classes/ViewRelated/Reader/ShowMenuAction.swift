final class ShowMenuAction {
    private let isLoggedIn: Bool

    init(loggedIn: Bool) {
        isLoggedIn = loggedIn
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, topic: ReaderSiteTopic? = nil, readerTopic: ReaderAbstractTopic?, anchor: UIView, vc: UIViewController) {
        // Create the action sheet
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelActionWithTitle(ReaderPostMenuButtonTitles.cancel, handler: nil)

        // Block button
        if shouldShowBlockSiteMenuItem(readerTopic: readerTopic) {
            alertController.addActionWithTitle(ReaderPostMenuButtonTitles.blockSite,
                                               style: .destructive,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    BlockSiteAction(asBlocked: true).execute(with: post, context: context, completion: {})
                                                }
            })
        }

        // Notification
        if let topic = topic, isLoggedIn, post.isFollowing {
            let isSubscribedForPostNotifications = topic.isSubscribedForPostNotifications
            let buttonTitle = isSubscribedForPostNotifications ? ReaderPostMenuButtonTitles.unsubscribe : ReaderPostMenuButtonTitles.subscribe
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let topic: ReaderSiteTopic = ActionHelpers.existingObject(for: topic.objectID, in: context) {
                                                    SubscribingNotificationAction().execute(for: topic.siteID, context: context, value: !topic.isSubscribedForPostNotifications)
                                                }
            })
        }

        // Following
        if isLoggedIn {
            let buttonTitle = post.isFollowing ? ReaderPostMenuButtonTitles.unfollow : ReaderPostMenuButtonTitles.follow
            alertController.addActionWithTitle(buttonTitle,
                                               style: .default,
                                               handler: { (action: UIAlertAction) in
                                                if let post: ReaderPost = ActionHelpers.existingObject(for: post.objectID, in: context) {
                                                    FollowAction().execute(with: post, context: context)
                                                }
            })
        }

        // Share
        alertController.addActionWithTitle(ReaderPostMenuButtonTitles.share,
                                           style: .default,
                                           handler: { (action: UIAlertAction) in
                                            ShareAction().execute(with: post, context: context, anchor: anchor, vc: vc)
        })

        if WPDeviceIdentification.isiPad() {
            alertController.modalPresentationStyle = .popover
            vc.present(alertController, animated: true, completion: nil)
            if let presentationController = alertController.popoverPresentationController {
                presentationController.permittedArrowDirections = .any
                presentationController.sourceView = anchor
                presentationController.sourceRect = anchor.bounds
            }

        } else {
            vc.present(alertController, animated: true, completion: nil)
        }
    }

    fileprivate func shouldShowBlockSiteMenuItem(readerTopic: ReaderAbstractTopic?) -> Bool {
        guard let topic = readerTopic else {
            return false
        }
        if isLoggedIn {
            return ReaderHelpers.isTopicTag(topic) || ReaderHelpers.topicIsFreshlyPressed(topic)
        }
        return false
    }
}