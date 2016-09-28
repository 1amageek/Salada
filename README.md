<img src="https://github.com/1amageek/Salada/blob/master/Salada.png", width="480">

Logo was designed by [Take](https://dribbble.com/take_designer).

# Salada 🍐
<!--
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
-->
Salad is a Model for Firebase database. It can handle Snapshot of Firebase easily.

## Requirements ❗️
- iOS 8 or later
- Swift 2.3
- [Firebase database](https://firebase.google.com/docs/database/ios/start)
- [Firebase storage](https://firebase.google.com/docs/storage/ios/start)

## Installation ⚙
<!--
#### [Carthage] (https://github.com/Carthage/Carthage)

- Insert `github "1amageek/Salada"` to your Cartfile.
- Run `carthage update`
- Link your app with Salada.framework in Carthage/Checkouts.
-->

Add the following to the pod file, `Pods install`

``` ruby
pod 'Firebase'
pod 'Firebase/Database'
pod 'Firebase/Storage'
```

1. [Download this project](https://github.com/1amageek/Salada/archive/master.zip)
1. Put `Salada.Swift` in your project.

## Usage 👀

### Model

Model of the definition is very simple.
To inherit the `Ingredient`.

``` Swift 
class User: Ingredient {
    typealias Tsp = User
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
}
```

When you want to create a property that you want to ignore.

``` Swift
// Group
class Group: Ingredient {
    typealias Tsp = Group
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
| NSURL | URL |
| NSDate | date |
| Array\<String\> | Array of strings. |
| Set \<String\>| Array of strings. Set is used in relationships. |
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
```

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

<img src="https://github.com/1amageek/Salada/blob/master/Sample/sample_code_0.png" width="400">

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
class User: Ingredient {
    typealias Tsp = User
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
    dynamic var location: CLLocation?
    dynamic var url: NSURL?
    dynamic var birth: NSDate?
    dynamic var thumbnail: File?
    dynamic var type: UserType = .first
    
    var tempName: String? 
    
    override var ignore: [String] {
        return ["tempName"]
    }
    
    override func encode(key: String, value: Any) -> AnyObject? {
        if key == "location" {
            if let location = self.location {
                return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
            }
        } else if key == "type" {
            return self.type.rawValue
        }
        return nil
    }
    
    override func decode(key: String, value: Any) -> Any? {
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

``` Swift
let user: User = User()
let image: UIImage = UIImage(named: "Salada")!
let data: NSData = UIImagePNGRepresentation(image)!
let thumbnail: File = File(data: data)
user.thumbnail = thumbnail
user.save({ (error, ref) in
    // do something
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

# Salada datasource

see SaladBar

For example 

``` Swift
// in ViewController property
var datasource: Salada<Group, User>?
```

``` Swift
// in viewDidLoad
let options: SaladaOptions = SaladaOptions()
options.limit = 10

self.datasource = Salada(with: ref.key, referenceKey: "users", options: options, block: { [weak self](changes) in
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
```

``` Swift
// TableViewDatasource
func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.datasource?.count ?? 0
}
    
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
    configure(cell, atIndexPath: indexPath)
    return cell
}

func configure(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
    self.datasource?.observeObject(at: indexPath.item, block: { (user) in
        cell.imageView?.contentMode = .scaleAspectFill
        cell.textLabel?.text = user?.name
    })
}

func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    self.datasource?.removeObserver(at: indexPath.item)
}

func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
    return true
}

func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        self.datasource?.removeObject(at: indexPath.item, block: { (error) in
            if let error: Error = error {
                print(error)
            }
        })
    }
}
```
