
# GitHub-SearchAPI-Example

Github Search repositories API를 이용하여 만든 예제 앱 입니다.

📎 [시연 영상](https://drive.google.com/file/d/1pNzCquYW2qnFr6-vLOty0SeguGg9Br_T/view?usp=drive_link)


## 📁 프로젝트 구조
```
📂 SearchRepository
 ├── 📂 Domain       # 도메인 레이어
 │    ├── 📂 Models  # 도메인 모델
 │    ├── 📂 Repository # 레포지토리 인터페이스
 ├── 📂 Network      # 데이터 레이어 
 │    ├── 📂 API      # DTO
 │    ├── 📂 Response # DTO
 │    ├── 📂 Repository # 레포지토리 구현체
 │    ├── 📂 Error   # 커스텀 에러
 ├── 📂 domain       # 도메인 레이어
 │    ├── 📂 model   # 데이터 클래스
 │    ├── 📂 repository # Repository 인터페이스 정의
 │    ├── SearchRepoUseCase # 검색 기능 UseCase
 ├── 📂 Feature           # UI 레이어
 │    ├── 📂 component  # 공통 View
 │    ├── 📂 search    # 검색 기능
 │    ├── 📂 myRepository # 즐겨찾기 기능
 │    ├── 📂 RepositoryDetail  # 상세페이지 기능
```

**클린 아키텍처(Clean Architecture)** 를 적용하여  `data`, `domain`, `ui` 세 개의 주요 레이어로 구성하였습니다. 이를 통해 테스트하기 쉬운 구조를 갖고 각각의 레이어에 맞게 관심사 분리 및 에러 핸들링을 할 수 있도록 의도하였습니다.

## 🚀 주요 기능
- 레포지토리 검색 및 페이징
- 검색화면 네트워크 에러 핸들링
- 즐겨찾기


## 🛠️ 핵심 기능 설계
### 검색화면 네트워크 에러 핸들링

> 개요

Github Search API에는 RateLimit, SearchLimit이 존재합니다. 각각 1분당 요청 10회, 최대 검색 결과 1,000개라는 제한이 있습니다.
 
 그렇기 때문에 유저가 앱을 사용하는도중 이 limit에 걸려 에러를 마주칠 가능성이 매우 높습니다. 이에 대해 유저가 에러를 구분하고 적절한 행동을 할 수 있도록 에러 핸들링 구조를 설계하였습니다.

https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28

> 구조

```swift
enum SearchError: Error {
    case badServerResponse // 서버 통신 불량
    case tooManyRequest // rateLimit 초과
    case noMorePageAvailable // SearchLimit 혹은 페이징 중 더이상 결과가 없음
    case underlyingError(Error?) // 기타
```

에러 케이스를 구분하고 RepoDataRepository와 SearchRepoUseCase에서 SearchError를 발행합니다.


> 에러 화면

유저의 검색 상황을 고려하여 2가지 에러 화면을 구상하였습니다.

1. 새롭게 데이터를 서칭하는 상황(검색)
	- **검색 결과 화면**으로 직관적으로 네트워크 실패를 보여주고 기존 데이터를 초기화
2. 기존 데이터를 서칭하는 상황(페이징, Pull to refresh)
	- **토스트 화면**으로 네트워크 실패를 보여주고 서칭에 큰 방해가 되지 않도록 함

| 검색 결과 화면           | 토스트 화면              |
| ------------------ | ------------------- |
| <img src="https://github.com/user-attachments/assets/3dab7b69-c23b-43d9-b473-d110e4d5b4e5" width="250"> | <img src="https://github.com/user-attachments/assets/6a73433c-ace2-4f57-aa76-9c16400947c2" width="250"> |

<br/>
<br/>


### 즐겨찾기


> 개요

여러개의 화면에 걸쳐있는 즐겨찾기 데이터를 업데이트 해야했습니다. 데이터 흐름의 일관성을 갖기 위해 즐겨찾기 데이터를 바로 업데이트 하지않고 Publisher를 통해 값을 받아 업데이트 하도록 설계하였습니다.

> 구조

<img width="907" alt="즐겨찾기_기능구조" src="https://github.com/user-attachments/assets/529f68b2-04a2-466a-85da-0099e5693858" />

```swift
protocol FavoriteRepoDataMananger {
    var changedRepositoryData: AnyPublisher<FavoriteRepositoryData, Never> { get }
    func change(data: RepositoryData)
}
```


같은 Publisher를 갖도록 동일한 객체로 의존성 주입을 했습니다.


```swift

final class FeatureBuilder {

    private let favoriteRepoDataMananger = FavoriteRepoManangerImpl(userDefaults: UserDefaults(suiteName: "SearchRepository")! )

    func buildSearchViewController() -> SearchViewController {
        let router = DetailPageRouterImpl(favoriteRepoDataMananger: favoriteRepoDataMananger)
        let repository = RepoDataRepositoryImpl(favoriteRepository: favoriteRepoDataMananger)
        let useCase = SearchRepoUseCaseImpl(repository: repository)
        let viewModel = SearchViewModel(repoUseCase: useCase, favoriteRepoDataMananger: favoriteRepoDataMananger, router: router)
        let vc = SearchViewController(viewModel: viewModel)
        router.rootVC = vc
        return vc
    }
}


```


## 🔎 최적화
### Snapshot

Search 기능의 snapshot 업데이트 유형을 2가지로 나눠서 적용했습니다.

1. 새로운 스냅샷으로 모두 업데이트
	- Query 검색, Pull to refreash
2. 기존 스냅샷 이어서 업데이트
	- 페이징

```swift
enum SearchResultUpdateType {
    case all
    case continuous
}

private func updateSearchResultSnapshot(data: [RepositoryData.ID], type: SearchResultUpdateType) {
	switch type {
	case .all:
		var snapshot = NSDiffableDataSourceSnapshot<Int, RepositoryData.ID>()
		snapshot.appendSections([0])
		snapshot.appendItems(data)
		dataSource.apply(snapshot, animatingDifferences: false)
		if !data.isEmpty {
			scrollToFirstItem()
		}
	case .continuous:
		var snapshot = dataSource.snapshot()
		snapshot.appendItems(data)
		dataSource.apply(snapshot, animatingDifferences: true)
	}
}

```


즐겨찾기의 경우 개별 아이템 하나만 구분하여 업데이트 하도록 만들었습니다.

```swift
private func updateFavoritedSnapshot(data: RepositoryData.ID) {
	var snapshot = dataSource.snapshot()
	snapshot.reconfigureItems([data])
	dataSource.apply(snapshot, animatingDifferences: true)
}
```


### 캐싱

이미지 캐싱을 위해 **ImageProvider** 객체를 싱글톤으로 사용하여 이미지가 필요한 전역에서 캐싱하였습니다.

```swift
import UIKit

final class ImageProvider {

    static let shared = ImageProvider()

    private let imageCache = NSCache<NSString, UIImage>()

    func fetchImage(from urlString: String) async throws -> UIImage? {
        let urlNSString = NSString(string: urlString)
        if let cachedImage = imageCache.object(forKey: urlNSString) {
            return cachedImage
        }
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else { return nil }
        imageCache.setObject(image, forKey: urlNSString)
        return UIImage(data: data)
    }
}
```


**FavoriteRepoManangerImpl** 객체에서 즐겨찾기 시 로컬에 저장하는 RepositoryData를 메모리 캐싱하였습니다.

```swift

final class FavoriteRepoManangerImpl: FavoriteRepoDataMananger, FavoriteRepository {

    private var repositoryCache: [RepositoryData.ID : RepositoryData]?
    private var repositoryDict: [RepositoryData.ID : RepositoryData] {
        get {
            if let cache = repositoryCache {
                return cache
            }
            if let data = userDefaults.data(forKey: Key.repositoryData), let decodedData = try? decoder.decode([RepositoryData].self, from: data) {
                let dict = decodedData.reduce(into: [:]) { dict, repo in
                    dict[repo.id] = repo
                }
                repositoryCache = dict
                return dict
            }
            return [:]
        }
        set {
            repositoryCache = newValue
            userDefaults.set(try? encoder.encode(newValue.values.map{ $0 }) , forKey: Key.repositoryData)
        }
    }

    func change(data: RepositoryData) {
        let isFavorite = !data.isFavorite
        let favoriteRepositoryData = FavoriteRepositoryData(id: data.id, favorite: isFavorite)
        if isFavorite {
            var newData = data
            newData.isFavorite = true
            repositoryDict[newData.id] = newData
        } else {
            repositoryDict.removeValue(forKey: data.id)
        }
        favoriteSubject.send(favoriteRepositoryData)
    }
}

```


이를 즐겨찾기 페이지, 새로운 검색결과를 받을때 사용하였습니다.


## ✨ 추가 기능
### 검색 결과 화면

> 검색 결과가 없는 것과 네트워크 실패에 따른 검색 결과가 구분되어야한다고 생각하여 추가하였습니다.

| 검색 결과 없음                 | 네트워크 실패               |
| ------------------------ | --------------------- |
| <img width="250" alt="검색결과_데이터없음" src="https://github.com/user-attachments/assets/b10ddf72-df2a-4c15-b381-12983aadf863" /> | <img width="250" alt="검색결과_에러" src="https://github.com/user-attachments/assets/b61022eb-66ae-4fc8-a035-ec16df2e8526" /> |

### 네트워크 꺼져있을 시 오프라인 표시
> 사용자에게 오프라인 상태라는 것을 직관적으로 표시하면 좋을 것 같아서 추가하였습니다.

<img width="250" alt="검색결과_데이터없음" src="https://github.com/user-attachments/assets/c08d29fa-cb40-40fd-940b-a2755d6bffd2" />


### 소소한 디테일
- 새롭게 검색 시 스크롤을 첫번째 아이템으로 이동
- 키보드 내리기
	- 화면터치 시
    - 스크롤 시
- 검색 시 현재 보여지는 목록을 숨겼다가 검색 결과가 나오면 다시 목록 보여주기

## 🧪 테스트 코드

> 구체적인 구현을 테스트하지 않고, 기대하는 동작에 대한 테스트하고자 하였습니다.

**SearchViewModel**
1. 검색
    - "검색 결과가 없음"에 대한 테스트 (빈 데이터, UI 상태)
        - 검색했을 때 검색 결과가 없다면, 검색 결과를 빈 데이터로 전체 초기화
        - 검색했을 때 검색 결과가 없다면, 검색 결과가 없음을 표시
    - "검색 결과가 있음"에 대한 테스트 (데이터 업데이트, UI 상태)
        - 검색했을 때 검색 결과가 있다면, 검색 결과를 전체 업데이트
        - 검색했을 때 검색 결과가 있다면, 검색 결과를 표시
    - "검색 예외 상황"에 대한 테스트 (쿼리 없음, 로딩 중, 오류 발생)
        - 검색했을 때 검색 쿼리가 없다면, 초기 검색 화면을 표시
        - 검색했을 때 오류가 발생한다면 오류를 표시
        - 검색중에 새로운 검색 요청은 무시
2. 페이징
    - 페이징 했을 때 검색 결과를 이어서 업데이트
    - 페이징 했을 때 오류가 발생한다면 오류를 표시
    - 페이징중에 새로운 페이징 요청은 무시
3. 복합 동작
    - 검색 후 페이징 시 페이지 증가
    - 페이징 중 검색 시 페이지 초기화
4. 즐겨찾기 변경
    - 즐겨찾기를 변경하면 변경 결과 업데이트

**SearchRepositoryDataUseCaseImpl**
- 검색 쿼리가 없다면 빈 검색 결과를 반환
- 페이징 중 검색 결과가 없다면 페이징을 중단

**FavoriteRepositoryDataManangerImpl**
- 로컬 저장소에 저장된 데이터를 패칭
- 즐겨찾기를 변경했을때 즐겨찾기한 데이터는 로컬저장소에_저장
- 즐겨찾기를 변경했을때 즐겨찾기를 취소한 데이터는 로컬데이터에서 삭제


## 💡추가 개선점
- 즐겨찾기 데이터 없을 때 표시
- ETag, 304 Not modified를 이용하여 refreash 최적화
- 접근성 (폰트, 다크모드)
- 검색 필터링
