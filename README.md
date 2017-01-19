Forked from maxlapshin/mysql2postgres

#### Fork updates/fixes:
* added option to update primary keys at the end of database transition
* changed mysql-pr dependency to the fixed fork (fixed encoding issue, fixed unexpected symbol at the end of file)
* added database transition logging 

To enable primary keys updating, add "update_primary_keys: true" to the config file

## License

Licensed under [the MIT license](MIT-LICENSE).
