# json-csv

This is a command-line tool that converts JSON files into CSV format and vice versa. See the examples in `Data`.

This is very useful because the CSVs can be imported and exported from LibreOffice or Excel, where you can use formulas to synchronize data across fields.

## CSV format

The rows in the CSV file correspond to different values depending on the optional `--column-format` argument of the command:

- **(default) standard:** the JSON is an object, and the rows correspond to top-level fields. Or, if the rows all start with a number, the JSON is an array, and the rows correspond to indices
- **array:** the JSON is a 3-dimensional staggered array. Each row must start with `#-#-#`, where each `#` is a number - this sequence of numbers is the index path of the row's corresponding JSON. This is used internally, in the future it might support arrays of different dimensions.

The columns in the CSV file correspond to property paths. For example, `car.model` corresponds to the property `model` inside of the property `car` (which is an object), inside of the object that corresponds to the entire row. 

You can also splice a CSV into an existing JSON, so that the CSV replaces one of the top-level fields of the JSON instead of being converted into its own file. This won't rearrange any of the other fields, either. *Note that this feature requires the [`jq` command-line tool](https://stedolan.github.io/jq/) to be installed.

## Building

`json-csv` is built using the [Swift Package Manager](https://swift.org/package-manager/). Run `swift build` to build, and `swift run ftd-data-convert <arguments ...>` to run.

You can run `test.sh` to perform some basic integration tests. The tests require [`jq`](https://stedolan.github.io/jq/) to work.