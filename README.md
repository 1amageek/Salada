# Salada 🍐

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Salad is a Model for Firebase database. It can handle Snapshot of Firebase easily.

## Requirements ❗️
- iOS 8 or later
- Swift 2.3
- [Firebase database](https://firebase.google.com/docs/database/ios/start)

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
```

1. [Download this project](https://github.com/1amageek/Salada/archive/master.zip)
1. Put `Salada.Swift` in your project.

## Usage 👀

### Model

Model of the definition is very simple.
To inherit the `Ingredient`.

``` Swift

// User
class User: Ingredient {
    typealias Tsp = User
    dynamic var name: String?
    dynamic var age: Int = 0
    dynamic var gender: String?
    dynamic var groups: Set<String> = []
    dynamic var items: [String] = []
}


```

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
| Array\<String\> | Array of strings. |
| Set \<String\>| Array of strings. Set is used in relationships. |

### Save and Update

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
