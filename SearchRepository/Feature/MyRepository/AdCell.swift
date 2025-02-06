import UIKit

class AdCell: UICollectionViewCell {

    static let reuseIdentifier = "AdCell"

    private var adData: [UIColor] = []

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPage = 0
        pc.currentPageIndicatorTintColor = .black
        pc.pageIndicatorTintColor = .lightGray
        return pc
    }()

    private let adCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .init(width: UIScreen.main.bounds.width, height: 80)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        adCollectionView.delegate = self
        adCollectionView.dataSource = self
        adCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "AdDataCell")

        contentView.addSubview(adCollectionView)
        contentView.addSubview(pageControl)

        adCollectionView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            adCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            adCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            adCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            adCollectionView.heightAnchor.constraint(equalToConstant: 80),

            pageControl.topAnchor.constraint(equalTo: adCollectionView.bottomAnchor, constant: 5),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with adData: AdData) {
        self.adData = adData.items.map{ item in
            switch item {
            case .red: return .red
            case .orange: return .orange
            case .green: return .green
            case .yellow: return .yellow
            }
        }
        pageControl.numberOfPages = adData.items.count
        adCollectionView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AdCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return adData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdDataCell", for: indexPath)

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let rectangleView = UIView()
        rectangleView.backgroundColor = adData[indexPath.item]
        rectangleView.layer.cornerRadius = 8
        rectangleView.layer.masksToBounds = true

        let label = UILabel()
        label.text = "광고"
        label.font = .preferredFont(forTextStyle: .title3)

        rectangleView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(rectangleView)
        cell.contentView.addSubview(label)

        NSLayoutConstraint.activate([
            rectangleView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            rectangleView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            rectangleView.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: 0.8),
            rectangleView.heightAnchor.constraint(equalTo: cell.contentView.heightAnchor, multiplier: 0.7),
            label.centerXAnchor.constraint(equalTo: rectangleView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: rectangleView.centerYAnchor)
        ])

        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageControl.currentPage = pageIndex
    }
}

extension AdCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}
