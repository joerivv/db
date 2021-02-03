# db
A simple, local database tool.
 - One database = one table = one file.
 - There is no schema. Fields (columns) are based on input data.
 - XML storage, for bigger databases you can opt into XMLDB (an SQLite wrapper)
 - Import from CSV
 - Export to XML, CSV, TSV, JSON, TXT, PHP, or just a simple list
 - Retrieve data from the command line, from an http server or through js scripts  

## Quick Start

Create a databae:
```
$ db coffee
```

Import data from a file:
```
$ db coffee import beans.csv
$ db coffee import beans.tsv
$ db coffee import beans.json
$ db coffee import beans.xlsx
```

Get all records:
```
$ db coffee as xml
$ db coffee as json
$ db coffee as txt
$ db coffee as csv
$ db coffee as csv --tabs
$ db coffee as tsv
$ db coffee as php
$ db coffee as php --shortened
$ db coffee as list
```

Set up a local server to use from local web apps
```bash
$ db coffee serve
Serving coffee on http://localhost:7777
```
```javascript
fetch("http://localhost:7777")
    .then(result => result.json())
    .then(records => console.log(records))
```


## Create  database
To create a database 'coffee' in the active working directory, run:
```
$ db coffee
```

## Add data

`db` supports five ways to add data:
 - Using the `import` command, for importing data from files
 - Using the `add` command, for importing from string literals
 - Using a POST-method call to the endpoint of running a server with `serve` (this adds data)
 - Using a PUT-method call to the endpoint of running a server with `serve` (this replaces data)
 - By modifying the XML-file directly

The following file types are recognised:
 - .csv
 - .tsv
 - .xlsx (Excel)

The following string literal interpretations are recognised:
 - Single values
 - Comma-separated (CSV)
 - Tab-delimited (TSV)
 - JSON
 - PHP associative arrays
 - TXT

You can also import proprietary data using a custom import scheme.

### Import from CSV file
```
$ db coffee import beans.csv
```
Sometimes, CSV files actually contain tab-delimited records. This is detected automatically. If you want to force a comma-delimited interpretation, use:
```
$ db coffee import beans.csv --type csv
```
If the file containing CSV data doesn't have a '.csv'-extension, you must specify it:
```
$ db coffee import beans.txt --type csv
```

### Import from TSV file
```
$ db coffee import beans.tsv
```
If the file containing TSV data doesn't have a '.tsv'- or '.csv'-extension, you must specify it:
```
$ db coffee import beans.txt --type tsv
```

### Import from XSLX file (Excel)
```
$ db coffee import beans.xlsx
```
Older Excel files (with extension '.xls') are not supported. Up to one table per worksheet is recognised. Tables must be vertically oriented.

### String input

When you add data from a string input, the type is automatically inferred. `value`, `csv`, `tsv`, `json`, `php`, and `txt` are recognised. You can also force one of these types with the `--type` option.

#### Value
```
$ db coffee add "Robusta"
```
A field is assigned based on existing records.

You can also specify it manually:
```
$ db coffee add "Robusta" --headers "bean"
```

Resulting XML:
```
<record>
    <bean>Robusta</bean>
</record>
```

#### CSV
```
$ db coffee add "Robusta,Coffea,2.7%"
```
Field names are assigned automatically based on existing records.

You can also specify them manually:
```
$ db coffee add "Robusta,Coffea,2.7%" --headers "bean,genus,caffeine"
```

If the CSV input contains multiple lines, the first one is automatically taken to be the header:
```
$ db coffee add "bean,genus,caffeine\nRobusta,Coffea,2.7%"
```

Resulting XML:
```
<record>
    <bean>Robusta</bean>
    <genus>Coffea</genus>
    <caffeine>2.7%</caffeine>
</record>
```

#### TSV

TSV interpretation works just like CSV, except with tab characters instead of commas:
```
$ db coffee add "Robusta\tCoffea\t2.7%"
```

Resulting XML (given previous records):
```
<record>
    <bean>Robusta</bean>
    <genus>Coffea</genus>
    <caffeine>2.7%</caffeine>
</record>
```

#### JSON
```
$ db coffee add "{'bean':'Robusta'}"
```

Resulting XML:
```
<record>
    <bean>Robusta</bean>
</record>
```

JSON arrays containing objects are supported for inserting multiple values:
```
$ db coffee add "[{'bean':'Robusta'},{'bean':'Arabica'}]"
```

Resulting XML:
```
<record>
    <bean>Robusta</bean>
</record>
<record>
    <bean>Arabica</bean>
</record>
```

#### PHP

PHP associative arrays are recognised:
```
$ db coffee add "array('bean'=>'Robusta')"
```

PHP flat arrays containing associative arrays are supported for inserting multiple values:
```
$ db coffee add "array(array('bean'=>'Robusta'),array('bean'=>'Arabica'))"
```

The shorthand syntax is also supported:
```
$ db coffee add "['bean'=>'Robusta']"
$ db coffee add "[['bean'=>'Robusta'],['bean'=>'Arabica']]"
```

#### TXT

When newlines outnumber commas and tab characters in multiline input, each row is treated as a new record: 
```
$ db coffee add "Robusta\nArabica"
```

Resulting XML (given previous records):
```
<record>
    <bean>Robusta</bean>
</record>
<record>
    <bean>Arabica</bean>
</record>
```

A special case exists where double newlines separate records, making room for property enlistments:
```
$ db coffee add "bean:Robusta\ncaffeine:2.7%\n\nbean:Arabica\ncaffeine:1.5%"
```

Resulting XML:
```
<record>
    <bean>Robusta</bean>
    <caffeine>2.7%</caffeine>
</record>
<record>
    <bean>Arabica</bean>
    <caffeine>1.5%</caffeine>
</record>
```

### Custom import

To import a proprietary data format, use `--pattern` followed by a valid regular expression. The combination works with the `import` command (for files) as well as with `add` (for string input).

Use named capture groups to assign meaning:
 - `record` for each record
 - `value` for any value in a record
 - `field` for the field specifier in a key-value pair based data structure

In a value-based structure, use a separate pattern as part of a `--fields` option to parse the headers. If headers are not present in the data, they will be automatically determined based on existing records. You an also specifiy them with the `--headers` option. 

#### Example: JSON

Let's say JSON was not supported. Here's how we could still import it:

Let's begin with the basic structure:
`[{"field":value}]`

Now escape what has special meaning in regular expressions:
`\[\{"field":value\}\]`

Make the field name and value variable:
`\[\{".+":.+\}\]`

Commas separate property-value pairs and successive objects, so we have to allow for these:
`\[\{".+":.*,?\},?\]`

Create the first capture group for the record repetition:
`\[(?<record>\{".+":.*,?\},?)*\]`

Allow field-value pairs to repeat:
`\[(?<record>\{(".+":.*,?)*\},?)*\]`

Create field and value capture groups:
`\[(?<record>\{("(?<field>.+)":(?<value>.*),?)*\},?)*\]`

Since we're not interested in quotation marks for values, we can make them optional:
`\[(?<record>\{("(?<field>.+)":["']?(?<value>.*)["']?,?)*\},?)*\]`

Finally, to be able to use this pattern in the command line, we have to escape the double quotes:
`\[(?<record>\{(\"(?<field>.+)\":[\"']?(?<value>.*)[\"']?,?)*\},?)*\]`

To import from a file, you can now use:
```
$ db coffee import beans.json --pattern "\[(?<record>\{(\"(?<field>.+)\":[\"']?(?<value>.*)[\"']?,?)*\},?)*\]"
```

Caveats:
 - It doesn't allow for whitespace
 - It assumes an array, not a single object or value
 - No type checking
 - Properties must be quoted

Pattern must be extended considerably to aleviate these shortcomings.

### Example: CSV

Here's an example of what a custom CSV parser might look like (assumes the presence of a header and does not support quoted values):
```
$ db coffee import beans.csv --pattern "[^\n]+\n(?<record>(?<value>.*,?)*)" --fields "^(?<field>.*,?)*\n.*"
```

## Export data
```
$ db coffee as json
```
You can subsitute json for xml, csv, tsv, txt, php, or list.

Output is writtten to _stdout_, so you'll instantly see the results. To write to a file, simply redirect:
```
$ db coffee as csv > coffee.csv
```

For csv specifically, you can request tab separators instead of comma separators:
```
$ db coffee as csv --tabs
```

This is equivalent to:
```
$ db coffee as tsv
```

To get values only, use `list`:
```
$ db coffee as list
```

### Access from JavaScript

For security reasons, JavaScript does not allow you to access local files from a web browser. So to use a database for a local app, `db` has a `serve` command.

From the command line, run:
```
$ db coffee serve
Serving coffee on http://localhost:7777
```

Now from JavaScript, you can access all records as json:
```
fetch("http://localhost:7777")
    .then(result => result.json())
    .then(records => {
        // do your thing
    }))
```

### Access from Node.js

Simplest is probably just to read the xml file directly:
```
const fs = require('fs');
const convert = require('xml2json');

fs.readFile('coffee.xml', (err, xml) => {
    const json = convert.toJson(xml);
    const result = JSON.parse(json);
    const records = result.data.record;
    // do your thing
});
```

You can also run a shell command:
```
const { exec } = require("child_process");

exec("db coffee as json", (error, stdout, stderr) => {
    const records = JSON.parse(stdout);
    // do your thing
});
```

### Access from PHP
```
$records = eval(shell_exec('db coffee as php'));
// do your thing
```

From PHP 5.4, you can also request the short array syntax:
```
$records = eval(shell_exec('db coffee as php --shortened'));
// do your thing
``` 

Alternatively, you can parse the xml file:
```
$xml = simplexml_load_file('coffee.xml');
$records = $xml->data->record
// do your thing
```

## Deleting stuff
```
$ db coffee delete --all
$ db coffee delete --duplicates
$ db coffee delete --where id=4
$ db coffee delete --field location
```
Add `--dry` to see what would be deleted without deleting anything.

## Creating backups

Just copy the associated xml or xmldb file. You can do this through the command line if you wish:
```
$ cp coffee.xml coffee_backup.xml
```

### If you lose the `db` command

Don't worry, it's just xml. Trivial to extract your data. In the command line, you could use `cat coffee.xml` to view or `nano coffee.xml`/`vi coffee.xml` to edit.

If you have a compressed database, with extension '.xmldb', you can use sqlite3 to access it (comes standard on mac):
```
$ sqlite3 coffee.xmldb
SQLite version 3.32.3
Enter ".help" for usage hints.
sqlite> .headers on
sqlite> select * from 'data';
```


