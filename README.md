# The Awesomizer
This project contains two sets of Ruby scripts developed for the CUL [Library Outside the Library](http://labs.library.cornell.edu)'s [Awesomizer](http://awesome.library.cornell.edu). The Awesomizer is an experimental library barcode reader and database.

Scripts are divided into two directories:

- Scripts under **pi** are intended to run on a Raspberry Pi with an attached USB barcode scanner and, optionally, a set of LEDs connected to the Pi's GPIO pins. *lol_blink.rb* is a set of functions for controlling LEDs. *read_barcode.rb*, in addition to controlling LEDs, runs a continuous loop that waits for a barcode to be scanned and then sends the barcode off to be processed by a separate web service.

- The one script under **server**, *awesomizer.rb*, uses the Sinatra web server to provide two basic web services:
	1. Receive a request containing a barcode, do a lookup of that barcode in a Voyager database, then store metadata about the associated item (Bib ID) in a custom MySQL database. (This requires the Oracle Instant Client libraries to be installed on the server.)
	2. Return a JSON-formatted list of all the items in the database. This can be used as a data feed for a website set up to display items that have been "awesomized."
