/*
 Section
 - Header model
 Section
 - Post Cell model
 Section
 - Action Buttons Cell model
 Section
 - n Number of general models for comments
 
 */

import UIKit

class PostViewController: UIViewController {
    private let post: Post
    private let owner: String
    
    private var collectionView: UICollectionView?
    
    private var viewModels: [HomeFeedCellType] = []
    
    // MARK: - Init
    
    // UserPost optional is for the test
    init(
        post: Post,
        owner: String
        
    ) {
        self.owner = owner
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Post"
        view.backgroundColor = .systemBackground
        configureCollectionView()
        fetchPost()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView?.frame = view.bounds
    }
    
    private func fetchPost() {
        // test data
        let username = owner
        DatabaseManager.shared.getPost(with: post.id, from: username) { [weak self] post in
            guard let post = post else {
                return
            }
            self?.createViewModel(
                model: post,
                username: username,
                completion: { success in
                    guard success  else {
                        print("failed to create VM")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.collectionView?.reloadData()
                    }
                }
            )
        }
    }
        
        private func createViewModel(
            model: Post,
            username: String,
            completion: @escaping (Bool) -> Void
        ) {
            StorageManager.shared.profilePictureURL(for: username) { [weak self] profilePictureURL in
                guard let postUrl = URL(string: model.postUrlString),
                      let profilePhotoUrl = profilePictureURL else {
                    return
                }
                
                let postData: [HomeFeedCellType] = [
                    .poster(viewModel: PosterCollectionViewCellViewModel(
                        username: username,
                        profilePictureURL: profilePhotoUrl
                    )
                    ),
                    .post(viewModel: PostCollectionViewCellViewModel(
                        postURL: postUrl
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
                self?.viewModels = postData
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
            collectionView.register(
                CommentCollectionViewCell.self, forCellWithReuseIdentifier: CommentCollectionViewCell.identifier
            )
            self.collectionView = collectionView
        }
    }

extension PostViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }
    

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellType = viewModels[indexPath.row]
        
        switch cellType {
        
        case .poster(let viewModel):
           guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.identifier,
                for: indexPath
            ) as? PosterCollectionViewCell else {
                fatalError()
            }
            cell.delegate = self
            cell.configure(with: viewModel, index: indexPath.section)
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
            cell.configure(with: viewModel, index: indexPath.section)
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

extension PostViewController: PosterCollectionViewCellDelegate {
    func posterCollectionViewCellDidTapMore(_ cell: PosterCollectionViewCell, index: Int) {
        let sheet = UIAlertController(title: "Post Actions", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.addAction(UIAlertAction(title: "Share Post", style: .default, handler: { [weak self] _ in
            DispatchQueue.main.async {
                let cellType = self?.viewModels[index]
                switch cellType {
                case .post(let viewModel):
                    let vc = UIActivityViewController(
                        activityItems: ["Sharing from Instagram", viewModel.postURL],
                        applicationActivities: [])
                    self?.present(vc, animated: true)
                default:
                    break
                }
            }
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

extension PostViewController: PostCollectionViewCellDelegate {
    func postCollectionViewCellDidLike(_ cell: PostCollectionViewCell) {
        print("did tap to like")
    }
}

extension PostViewController: PostActionsCollectionViewCellDelegate {
    func postActionsCollectionViewCellDidTapLike(_ cell: PostActionsCollectionViewCell, isLiked: Bool, index: Int) {
        // call DB to update like state
    }
    
    func postActionsCollectionViewCellDidTapComment(_ cell: PostActionsCollectionViewCell, index: Int) {
//        let vc = PostViewController(post: )
//        vc.title = "Post"
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    func postActionsCollectionViewCellDidTapShare(_ cell: PostActionsCollectionViewCell, index: Int) {
        let cellType = viewModels[index]
        switch cellType {
        case .post(let viewModel):
            let vc = UIActivityViewController(
                activityItems: ["Sharing from Instagram", viewModel.postURL],
                applicationActivities: [])
            present(vc, animated: true)
        default:
            break
        }
    }
}

extension PostViewController: PostLikesCollectionViewCellDelegate {
    func postLikesCollectionViewCellDidTapLikeCount(_ cell: PostLikesCollectionViewCell) {
        let vc = ListViewController(type: .likers(usernames: []))
        vc.title = "Liked By"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension PostViewController: PostCaptionCollectionViewCellDelegate {
    func postCaptionCollectionViewCellDidTapCaption(_ cell: PostCaptionCollectionViewCell) {
        print("Caption Tapped")
    }
   
}
