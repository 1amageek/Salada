<div style="text-align: center; width: 100%">
<img src="https://github.com/1amageek/Salada/blob/master/logo.png", width="100%">

 [![Version](http://img.shields.io/cocoapods/v/Salada.svg)](http://cocoapods.org/?q=Salada)
 [![Platform](http://img.shields.io/cocoapods/p/Salada.svg)](http://cocoapods.org/?q=Salada)
 [![Downloads](https://img.shields.io/cocoapods/dt/Salada.svg?label=Total%20Downloads&colorB=28B9FE)](https://cocoapods.org/pods/Salada)

</div>

# Salada 🍐
<!--
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
-->
Salad is a Model for Firebase database. It can handle Snapshot of Firebase easily.

[Make a Model with Salada](https://medium.com/@1amageek/make-a-user-model-using-firebase-model-framework-salada-8c343fbe8800)

 - [x] You no longer need to create a server.  
 - [x] You no longer need to make a mock.  
 - [x] It operates in real time.  
 - [x] You can create a reactive UI.  

## Requirements ❗️
- iOS 10 or later
- Swift 4.0 or later
- [Firebase firestore](https://firebase.google.com/docs/database/ios/start)
- [Firebase storage](https://firebase.google.com/docs/storage/ios/start)
- [Cocoapods](https://github.com/CocoaPods/CocoaPods/milestone/32) 1.4 ❗️  ` gem install cocoapods --pre `

## Installation ⚙
#### [CocoaPods](https://github.com/cocoapods/cocoapods)

- Insert `pod 'Salada' ` to your Podfile.
- Run `pod install`.


## Usage 👀

### Model

Model of the definition is very simple.
To inherit the `Object`.

``` Swift
class User: Object {

    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    dynamic var url: URL?
    dynamic var birth: Date?
    dynamic var thumbnail: File?
    dynamic var followers: Relation<User> = []
}
```

When you want to create a property that you want to ignore.

``` Swift
// Group
class Group: Object {
    dynamic var name: String?
    dynamic var users: Set<String> = []
}
```

### Property

Property are four that can be specified in Salada.

| Property | Description |
| --- | --- |
| String | Simple string. |
| Number\(Int, UInt, Double ...\) | Simple number. |
| URL | URL |
| Date | date |
| Array\<String\> | Array of strings. |
| Set \<String\>| Array of strings. Set is used in relationships. |
| Reation\<Object\>| Reference |
| [String: Any] | Object |
| AnyObject | Use encode, decode function. |

⚠️ `Bool`, `Int`, `Float`, and `Double` are not supported optional types. 

### Save and Update

**Do not forget to change the database rules.**

```
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
// This rule is dangerous. Please change the rules according to the model
```

https://firebase.google.com/docs/database/security/

The new model is stored in the `save()` or `save(completion: ((NSError?, FIRDatabaseReference) -> Void)?)`.
It is updated automatically when you change the property Model that has already been saved.

``` Swift
let group: Group = Group()
group.name = "iOS Development Team"
group.save { (error, ref) in

    do {
        let user: User = User()
        user.name = "john appleseed"
        user.gender = "man"
        user.age = 22
        user.items = ["Book", "Pen"]
        user.groups.insert(ref.key)
        user.save({ (error, ref) in
            group.users.insert(ref.key) // It is updated automatically
        })
    }

    do {
        let user: User = User()
        user.name = "Marilyn Monroe"
        user.gender = "woman"
        user.age = 34
        user.items = ["Rip"]
        user.groups.insert(ref.key)
        user.save({ (error, ref) in
            group.users.insert(ref.key) // It is updated automatically
        })
    }

}
```

<img src="https://github.com/1amageek/Salada/blob/master/SaladBar/sample_code_0.png" width="400">

### Retrieving Data

- `observeSingle(eventType: FIRDataEventType, block: ([Tsp]) -> Void)`
- `observeSingle(id: String, eventType: FIRDataEventType, block: (Tsp) -> Void)`


``` Swift
User.observeSingle(FIRDataEventType.Value) { (users) in
    users.forEach({ (user) in
        // do samething
        if let groupId: String = user.groups.first {
            Group.observeSingle(groupId, eventType: .Value, block: { (group) in
                // do samething
            })
        }
    })
}
```

### Remove Data
``` Swift

if let groupId: String = user.groups.first {
    Group.observeSingle(groupId, eventType: .Value, block: { (group) in
        group.remove()
    })
}

```

### Custom Property
``` Swift
class User: Salada.Object {

    override class var _version: String {
        return "v1"
    }

    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    dynamic var location: CLLocation?
    dynamic var url: URL?
    dynamic var birth: Date?
    dynamic var thumbnail: File?
    dynamic var cover: File?
    dynamic var type: UserType = .first

    var tempName: String?

    override var ignore: [String] {
        return ["tempName"]
    }

    override func encode(_ key: String, value: Any?) -> Any? {
        if key == "location" {
            if let location = self.location {
                return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
            }
        } else if key == "type" {
            return self.type.rawValue as AnyObject?
        }
        return nil
    }

    override func decode(_ key: String, value: Any?) -> Any? {
        if key == "location" {
            if let location: [String: Double] = value as? [String: Double] {
                self.location = CLLocation(latitude: location["latitude"]!, longitude: location["longitude"]!)
                return self.location
            }
        } else if key == "type" {
            if let type: Int = value as? Int {
                self.type = UserType(rawValue: type)!
                return self.type
            }
        }
        return nil
    }
}
```

#### Upload file

You can easily save the file if you use the File.
File saves the File in FirebaseStorage.

**Do not forget to change the storage rules.**

``` Swift
let user: User = User()
let image: UIImage = UIImage(named: "Salada")!
let data: NSData = UIImagePNGRepresentation(image)!
let thumbnail: File = File(data: data, mimeType: .jpeg)
user.thumbnail = thumbnail
user.save({ (error, ref) in
    // do something
})
```

``` Swift
let image: UIImage = #imageLiteral(resourceName: "salada")
let data: Data = UIImageJPEGRepresentation(image, 1)!
let file: File = File(data: data, mimeType: .jpeg)
item.file = file
let task: FIRStorageUploadTask = item.file?.save(completion: { (metadata, error) in
    if let error = error {
        print(error)
        return
    }
})
```



#### Download file

Download of File is also available through the File.

``` Swift
guard let user: User = self.datasource?.objectAtIndex(indexPath.item) else { return }
user.thumbnail?.dataWithMaxSize(1 * 2000 * 2000, completion: { (data, error) in
    if let error: NSError = error {
        print(error)
        return
    }
    cell.imageView?.image = UIImage(data: data!)
    cell.setNeedsLayout()
})
```

FirebaseUI makes it even easier to access.

``` Ruby
# Only pull in FirebaseUI Storage features
pod 'FirebaseUI/Storage', '~> 3.0'
```

``` Swift
User.observeSingle(friend, eventType: .value, block: { (user) in
    if let user: User = user as? User {
        if let ref: FIRStorageReference = user.thumbnail?.ref {
            cell.imageView.sd_setImage(with: ref, placeholderImage: #imageLiteral(resourceName: "account_placeholder"))
        }
    }
 })
```

# Relationship

Please use `Relation` to create a relationship between models.
It can be defined by inheriting Relation class.

``` swift
class Follower: Relation<User> {
    override class var _name: String {
        return "follower"
    }
}
```

``` swift
class User: Object {
    let followers: Follower = []
}
```
<img src="https://github.com/1amageek/Salada/blob/master/SaladBar/sample_code_1.png" width="400">

# Data Source

See SaladBar.

For example

``` Swift 
// ViewController Sample

var dataSource: DataSource<User>?

override func viewDidLoad() {
    super.viewDidLoad()
    
    let options: Options = Options()
    options.limit = 10
    options.sortDescirptors = [NSSortDescriptor(key: "age", ascending: false)]
    self.dataSource = DataSource(reference: User.databaseRef, options: options, block: { [weak self](changes) in
        guard let tableView: UITableView = self?.tableView else { return }
        
        switch changes {
        case .initial:
            tableView.reloadData()
        case .update(let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.endUpdates()
        case .error(let error):
            print(error)
        }
    })
}

```

``` Swift
// TableViewDatasource
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dataSource?.count ?? 0
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
    configure(cell, atIndexPath: indexPath)
    return cell
}

func configure(_ cell: TableViewCell, atIndexPath indexPath: IndexPath) {
    cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (user) in
        cell.imageView?.contentMode = .scaleAspectFill
        cell.textLabel?.text = user?.name
    })
}

private func tableView(_ tableView: UITableView, didEndDisplaying cell: TableViewCell, forRowAt indexPath: IndexPath) {
    cell.disposer?.dispose()
}

func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
    return true
}

func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        self.dataSource?.removeObject(at: indexPath.item, cascade: true, block: { (key, error) in
            if let error: Error = error {
                print(error)
            }
        })
    }
}
```

## Observe
You can receive data changes through observation.  
And easy to manage observation using `Disposer`.

```swift
class ViewController: UIViewController {
    private var disposer: Disposer<User>?

    override func viewDidLoad() {
        super.viewDidLoad()
        disposer = User.observe(userID, eventType: .value) { user in
             //...
        }
    }

    deinit {
        // ... auto remove observe internal disposer when it deinitialized.
        // or manually and clearly dispose
        // disposer?.dispose()
    }
}
```

Salada has `Disposer`, `AnyDisposer` and `NoDisposer`.  
See details: `Disposer.swift`


# Reference

- [Salada](https://github.com/1amageek/Salada) Firebase model framework.
- [Tong](https://github.com/1amageek/Tong) Tong is library for using ElasticSearch with Swift.
- [dressing](https://github.com/1amageek/dressing) Dressing provides the functionality of CloudFunctions to connect Firebase and ElasticSearch.


# Contributing

We welcome any contributions. See the [CONTRIBUTING](https://github.com/1amageek/Salada/blob/master/CONTRIBUTING.md) file for how to get involved.  

Saladaは日本製です。日本人のコントリビューター大歓迎🎉

