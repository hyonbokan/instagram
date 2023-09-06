//
//  NewHomeViewController.swift
//  Instagram
//
//  Created by Michael Kan on 2023/08/31.
//

import UIKit

class NewHomeViewController: UIViewController {

    private var collectionView: UICollectionView?
    
    private var viewModels = [[HomeFeedCellType]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureCollectionView()
        fetchPosts()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView?.frame = view.bounds
    }
    
    private func fetchPosts() {
        // test data
        guard let username = UserDefaults.standard.string(forKey: "username") else {
            return
        }

        DatabaseManager.shared.posts(for: username) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let posts):
                    print("\n\n\n Post: \(posts.count)")
                    let group = DispatchGroup()

                    posts.forEach { model in
                        group.enter()
                        self?.createViewModel(
                            model: model,
                            username: username,
                            completion: { success in
                                defer {
                                    group.leave()
                                }
                                if !success {
                                    print("failed to build VM")
                                }
                            }
                        )
                    }
                    group.notify(queue: .main) {
                        self?.collectionView?.reloadData()
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    private func createViewModel(
        model: Post,
        username: String,
        completion: @escaping (Bool) -> Void
    ) {
        StorageManager.shared.downloadURL(for: model) { [weak self] url in
            // The url is nil
            print("\n\n\n Username:\(username)")
            guard let postURL = url else {
                return
            }
            let postData: [HomeFeedCellType] = [
                .poster(viewModel: PosterCollectionViewCellViewModel(
                    username: username,
                    profilePictureURL: URL(
                        string: "https://github.githubassets.com/images/modules/profile/achievements/pull-shark-default.png")!
                    )
                ),
                .post(viewModel: PostCollectionViewCellViewModel(
                    postURL: postURL
                    )
                ),
                .actions(viewModel: PostActionsCollectionViewCellViewModel(
                    isLiked: false
                    )
                ),
                .likeCount(viewModel: PostLikesCollectionViewCellViewModel(
                    likers: []
                    )
                ),
                .caption(viewModel: PostCaptionCollectionViewCellViewModel(
                    username: username,
                    caption: model.caption
                    )
                ),
                .timestamp(viewModel: PostDateTimeCollectionViewCellViewModel(
                    date: DateFormatter.formatter.date(from: model.postedDate) ?? Date()
                    )
                )
            ]
            self?.viewModels.append(postData)
            completion(true)
        }
    }
    
    private func configureCollectionView() {
        let sectionHeight: CGFloat = 240 + view.width
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { index, _ in
            
            // Item - check the dimentions of the items
            let posterItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(60)
                )
            )
            
            let postItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalWidth(1)
                )
            )
            
            let actionsItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(40)
                )
            )
            
            let likeCountItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(40)
                )
            )

            let captionItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(60)
                )
            )
            
            let timestampItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(40)
                )
            )
            
            // Group
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(sectionHeight)
                ),
                subitems: [
                    posterItem,
                    postItem,
                    actionsItem,
                    likeCountItem,
                    captionItem,
                    timestampItem
                ]
            )
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            // adding space between sections
            section.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 0, bottom: 10, trailing: 0)
            return section
        }))
        
        view.addSubview(collectionView)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            PosterCollectionViewCell.self,
            forCellWithReuseIdentifier: PosterCollectionViewCell.identifier
        )
        collectionView.register(
            PostCollectionViewCell.self,
            forCellWithReuseIdentifier: PostCollectionViewCell.identifier
        )
        collectionView.register(
            PostActionsCollectionViewCell.self,
            forCellWithReuseIdentifier: PostActionsCollectionViewCell.identifier
        )
        collectionView.register(
            PostLikesCollectionViewCell.self,
            forCellWithReuseIdentifier: PostLikesCollectionViewCell.identifier
        )
        collectionView.register(
            PostCaptionCollectionViewCell.self,
            forCellWithReuseIdentifier: PostCaptionCollectionViewCell.identifier
        )
        collectionView.register(
            PostDateTimeCollectionViewCell.self,
            forCellWithReuseIdentifier: PostDateTimeCollectionViewCell.identifier
        )
        self.collectionView = collectionView
    }

}

extension NewHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels[section].count
    }
    

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellType = viewModels[indexPath.section][indexPath.row]
        
        switch cellType {
        
        case .poster(let viewModel):
           guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.identifier,
                for: indexPath
            ) as? PosterCollectionViewCell else {
                fatalError()
            }
            cell.delegate = self
            cell.configure(with: viewModel)
            return cell
            
        case .post(let viewModel):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostCollectionViewCell.identifier,
                 for: indexPath
             ) as? PostCollectionViewCell else {
                 fatalError()
             }
            cell.delegate = self
            cell.configure(with: viewModel)
            return cell
            
        case .actions(let viewModel):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostActionsCollectionViewCell.identifier,
                 for: indexPath
             ) as? PostActionsCollectionViewCell else {
                 fatalError()
             }
            cell.delegate = self
            cell.configure(with: viewModel)
            return cell
            
        case .likeCount(let viewModel):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostLikesCollectionViewCell.identifier,
                 for: indexPath
             ) as? PostLikesCollectionViewCell else {
                 fatalError()
             }
            cell.delegate = self
            cell.configure(with: viewModel)
            return cell
            
        case .caption(let viewModel):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostCaptionCollectionViewCell.identifier,
                 for: indexPath
             ) as? PostCaptionCollectionViewCell else {
                 fatalError()
             }
            cell.delegate = self
            cell.configure(with: viewModel)
            return cell
            
        case .timestamp(let viewModel):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostDateTimeCollectionViewCell.identifier,
                 for: indexPath
             ) as? PostDateTimeCollectionViewCell else {
                 fatalError()
             }
             cell.configure(with: viewModel)
             return cell
        }
    }
}

extension NewHomeViewController: PosterCollectionViewCellDelegate {
    func posterCollectionViewCellDidTapMore(_ cell: PosterCollectionViewCell) {
        let sheet = UIAlertController(title: "Post Actions", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.addAction(UIAlertAction(title: "Share Post", style: .default, handler: { _ in
            
        }))
        sheet.addAction(UIAlertAction(title: "Report Post", style: .destructive, handler: { _ in
            
        }))
        
        present(sheet, animated: true)
    }
    
    func posterCollectionViewCellDidTapUsername(_ cell: PosterCollectionViewCell) {
        let vc = ProfileViewController(user: User(username: "hyonbo", email: "hyonbo@gmail.com"))
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension NewHomeViewController: PostCollectionViewCellDelegate {
    func postCollectionViewCellDidLike(_ cell: PostCollectionViewCell) {
        print("did tap to like")
    }
}

extension NewHomeViewController: PostActionsCollectionViewCellDelegate {
    func postActionsCollectionViewCellDidTapLike(_ cell: PostActionsCollectionViewCell, isLiked: Bool) {
        // call DB to update like state
    }
    
    func postActionsCollectionViewCellDidTapComment(_ cell: PostActionsCollectionViewCell) {
        let vc = PostViewController(model: UserPost(identifier: "test", postType: .photo, thumbnailImage: URL(string: "https://github.githubassets.com/images/modules/profile/achievements/pull-shark-default.png")!, postURL:URL(string: "https://github.githubassets.com/images/modules/profile/achievements/pull-shark-default.png")!, caption: "Testing", likeCount: [], comment: [], createdDate: Date(), taggedUsers: [], owner: UserOld(username: "hyonbo", name: ("hyonbo", "kan"), profilePhoto: URL(string: "https://github.githubassets.com/images/modules/profile/achievements/pull-shark-default.png")!, birthDate: Date(), gender: .male, counts: UserCount(followers: 0, following: 0, posts: 0), joinDate: Date())))
        vc.title = "Comments"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func postActionsCollectionViewCellDidTapShare(_ cell: PostActionsCollectionViewCell) {
        let vc = UIActivityViewController(activityItems: ["Sharing from Instagram"], applicationActivities: [])
        present(vc, animated: true)
    }
}

extension NewHomeViewController: PostLikesCollectionViewCellDelegate {
    func postLikesCollectionViewCellDidTapLikeCount(_ cell: PostLikesCollectionViewCell) {
        let vc = ListViewController(data: [UserRelationship(username: "Test", name: "Test", type: .following)])
        vc.title = "Liked By"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension NewHomeViewController: PostCaptionCollectionViewCellDelegate {
    func postCaptionCollectionViewCellDidTapCaption(_ cell: PostCaptionCollectionViewCell) {
        print("Caption Tapped")
    }
}