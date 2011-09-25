SQLiteCache
===========

SQLiteCache is a gem to allow you cache slow operations in ruby code.
It provides a simple API to make it easy to add caching to your ruby code.


Installing
----------

You may get the latest stable version from Rubyforge. Source gems are also available.

    $ gem install sqlitecache


Loading sqlitecache gem itself
-----------------------

   require 'rubygems'
   require 'sqlitecache'


Example
-------

    cache = SqliteCache('my_cache.db')
    result = cache.do_cached('key') do
      my_intensive_operation
    end

Resources
---------

* GitHub Project: http://github.com/njh/ruby-sqlitecache
* Documentation: http://rdoc.info/github/njh/ruby-sqlitecache/master/frames


Contact
-------

* Author:    Nicholas J Humfrey
* Email:     njh@aelius.com
* Home Page: http://www.aelius.com/njh/
* License:   Distributes under the same terms as Ruby
