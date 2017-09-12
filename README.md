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

☑️ You no longer need to create a server.</br>
☑️ You no longer need to make a mock.</br>
☑️ It operates in real time.</br>
☑️ You can create a reactive UI.</br>

## Requirements ❗️
- iOS 8 or later
- Swift 3.0 or later
- [Firebase database](https://firebase.google.com/docs/database/ios/start)
- [Firebase storage](https://firebase.google.com/docs/storage/ios/start)

## Installation ⚙
<!--
#### [Carthage] (https://github.com/Carthage/Carthage)

- Insert `github "1amageek/Salada"` to your Cartfile.
- Run `carthage update`
- Link your app with Salada.framework in Carthage/Checkouts.
-->

<!--
__CocoaPods__

- Insert `pod 'Salada' ` to your Podfile.
- Run `pod install`.

Note: CocoaPods 1.1.0 is required to install Salada.

-->


 Add the following to the pod file, `Pods install`

 ``` ruby
 pod 'Firebase'
 pod 'Firebase/Database'
 pod 'Firebase/Storage'
 ```

 1. [Download this project](https://github.com/1amageek/Salada/archive/master.zip)
 1. Put `SaladaApp.swift`, `Referenceable.swift`, `Base.swift`, `Object.swift`, `File.swift`, `DataSource.swift` in your project.

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

| Propery | Description |
| --- | --- |
| String | Simple string. |
| Number\(Int, UInt, Double ...\) | Simple number. |
| URL | URL |
| Date | date |
| Array\<String\> | Array of strings. |
| Set \<String\>| Array of strings. Set is used in relationships. |
| [String: Any] | Object |
| AnyObject | Use encode, decode function. |

### Save and Update

<b>Do not forget to change the database rule</b>
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
It is updated automatically when you change the property Model that have already been saved.

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

### Custom property
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

<b>Do not forget to change the storage rule</b>

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

# DataSource

see SaladBar

For example

``` Swift 
// ViewController Sample

var dataSource: DataSource<User>?

override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.rightBarButtonItems = [
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add)),
        UIBarButtonItem(title: "Prev", style: UIBarButtonItemStyle.plain, target: self, action: #selector(prev))
    ]
    self.view.backgroundColor = UIColor.white
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

