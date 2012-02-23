rubyfit is here to help your sanity when working with FIT files.

This project contains the FIT SDK version 1.2, so pay your respects: [This is Ant](http://www.thisisant.com/pages/products/fit-sdk)

Anyone familiar with stream based XML processing should find using this library intuitive.  Create a callbacks class that responds to the callback events, and handle the events as needed.  Our callbacks class on [ridewithgps](http://ridewithgps.com) is more complex, as it needs states to properly process laps, etc, but the examples/fit\_callbacks.rb file should be a good starting place.

When I get more time I'll document the messages, but for now you can look in ext/rubyfit/rubyfit.c to see what fields are being passed.
