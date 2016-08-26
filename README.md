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
| NSRUL | URL. |
| Number\(Int, UInt, Double ...\) | Simple number. |
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
    
    var tempName: String? 
    
    override var ignore: [String] {
        return ["tempName"]
    }
    
    override func encode(key: String, value: Any) -> AnyObject? {
        if "location" == key {
            if let location = self.location {
                return ["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude]
            }
        }
        return nil
    }
    
    override func decode(key: String, value: Any) -> AnyObject? {
        if "location" == key {
            if let location: [String: Double] = value as? [String: Double] {
                return CLLocation(latitude: location["latitude"]!, longitude: location["longitude"]!)
            }
        }
        return nil
    }
}
```

#### Upload file

You can easily save the file if you use the SaladaFile.
SaladaFile saves the File in FirebaseStorage.

``` Swift
let user: User = User()
let image: UIImage = UIImage(named: "Salada")!
let data: NSData = UIImagePNGRepresentation(image)!
let thumbnail: SaladaFile = SaladaFile(name: "salada_test.png", data: data)
thumbnail.data = data
user.thumbnail = thumbnail
user.save({ (error, ref) in
    // do something
})
```

#### Download file

Download of File is also available through the SaladaFile.

``` Swift
guard let user: User = self.datasource?.objectAtIndex(indexPath.item) else { return }
user.thumbnail?.dataWithMaxSize(1 * 200 * 200, completion: { (data, error) in
    if let error: NSError = error {
        print(error)
        return
    }
    cell.imageView?.image = UIImage(data: data!)
    cell.setNeedsLayout()
})
```

# Salada datasource

For example 

``` Swift
// in ViewController property
var salada: Salada<User>?
```

``` Swift
// in viewDidLoad
self.salada = Salada.observe({ [weak self](change) in
    
    guard let tableView: UITableView = self?.tableView else { return }
    
    let deletions: [Int] = change.deletions
    let insertions: [Int] = change.insertions
    let modifications: [Int] = change.modifications
    
    tableView.beginUpdates()
    tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
    tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
    tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .Automatic)
    tableView.endUpdates()
    
})
```

``` Swift
// TableViewDatasource
func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.salada?.count ?? 0
}
    
func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath)
    configure(cell, atIndexPath: indexPath)
    return cell
}
    
func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
    guard let user: User = self.salada?.objectAtIndex(indexPath.item) else { return }
    cell.textLabel?.text = user.name
}
```
