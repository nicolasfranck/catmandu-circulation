#preinstall these modules

	Ubuntu: 
		make, gcc, libxml2-dev, libexpat1-dev, zlib1g-dev, elasticsearch, mongodb, mongodb-server, mongodb-dev
	Centos/Redhat:
    make, gcc, libxml2-devel, expat-devel, zlib-devel, elasticsearch, mongodb, mongodb-server, mongodb-devel

#update table 'request_reserve' (offical approval of a library their items can be requested through our request button)

  perl bin/update_request_reserve.pl libraries.csv

#update items in store

  perl bin/import_items.pl 

#Run the app

    plackup bin/app.pl

#now goto "http://localhost:5000" in your web browser

# License

(c) 2013, Ghent University.
