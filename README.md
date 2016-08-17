# Salada 🍐
Salad is a Model for Firebase database. It can handle Snapshot of Firebase easily.


## Usage 👀

### Model

Model of the definition is very simple.
To inherit the `Ingredients`.

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
        user.groups.insert(ref.key)
        user.save({ (error, ref) in
            group.users.insert(ref.key) //It is updated automatically
        })
    }
    
    do {
        let user: User = User()
        user.name = "Marilyn Monroe"
        user.gender = "woman"
        user.groups.insert(ref.key)
        user.save({ (error, ref) in
            group.users.insert(ref.key) //It is updated automatically
        })
    }
    
}
```

<img src="https://github.com/1amageek/Salada/blob/master/Sample/sample_code_0.png" width="400">
