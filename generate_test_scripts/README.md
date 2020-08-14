##### Generate test scripts dynamically using given xml file.

Use below command to pass xml, which generates all test scripts in current directory
```sh
>./createTestScritpts.pl --xml_file=</path/to/xml_file>
```

By default, if you don't provide xml_file path, it will fetch xml file from current directory.
```sh
>./createTestScripts.pl
```

To know other options use below command.
```sh
> ./createTestScripts --help
```

If any changes to required to test script, update __DATA__ token at the bottom after perl script 

