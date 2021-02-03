# db
A simple, local database tool.
 - One database = one table = one file.
 - XML storage, for bigger databases you can opt into XMLDB (an SQLite wrapper)
 - There is no schema. Fields (columns) are based on input data.
 - Import from CSV, TSV, JSON, XLSX, XML or plain lists
 - Export to XML, JSON, TXT, CSV, TSV, PHP, or a list of values
 - Retrieve data from the command line, from an HTTP server or through JavaScript scripts  

## Quick Start

Create a database named "coffee":
```console
$ db coffee
```

Import data:
```console
$ db coffee import beans.csv
$ db coffee import beans.json
$ db coffee import beans.xlsx
$ db coffee import -s "bean,caffeine\nRobusta,2.5%"
$ db coffee import -s "{\"bean\":\"Robusta\",\"caffeine\":\"2.5%\"}"
```

Get all records:
```console
$ db coffee as xml
$ db coffee as json
$ db coffee as txt
$ db coffee as csv
$ db coffee as csv --tabs
$ db coffee as tsv
$ db coffee as php
$ db coffee as php --short
$ db coffee as list
```

## Access through REST API
A built-in web server provides access through HTTP requests for use in local web apps.
```console
$ db coffee serve
Serving coffee on http://localhost:7777
```
```javascript
const coffee = "http://localhost:7777"

fetch(coffee)
    .then(result => result.json())
    .then(records => /* do your thing */)
```

## Access through JavaScript API
You can access and manipulate the database with JavaScript:
```console
$ db people run script.js
```

### Read/write database
```javascript
db.read()

for (let person of db.records) {
    person.fullName = person.firstName + " " + person.lastName
    delete person.firstName
    delete person.lastName
}

db.write()
```

### Working with files
```javascript
db.read()

let names = db.records.map(user => user.name).join("\n")

file("just-the-names.txt").write(names)
```

### Working with folders
```javascript
for (let item of folder("~/Downloads").items) {
    if (item.extension == "pkg") {
        item.trash()
    }
}
```

### Running shell commands
```javascript
let listing = shell("ls -la")
```

### Running AppleScript
```javascript
applescript('tell application "Finder" to activate')
```
