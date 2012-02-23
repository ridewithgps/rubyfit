rubyfit is here to help your sanity when working with FIT files.

This project contains the FIT SDK version 1.2, so pay your respects: [This is Ant](http://www.thisisant.com/pages/products/fit-sdk)

Anyone familiar with stream based XML processing should find using this library intuitive.

1. Create a callbacks class that responds to the callback events, and handle the events as needed.  Use the example fit\_callbacks.rb file as a guide - Our callbacks class on [ridewithgps](http://ridewithgps.com) is more complex, as it needs states to properly process laps, etc.
2. Pass in your callback class instance to the RubyFit::FitParser initializer.
3. Call parse() on your parser instance.

Example:

    raw = IO.read("myfitfile.fit")
    callbacks = FitCallbacks.new()
    parser = RubyFit::FitParser.new(callbacks)
    parser.parse(raw)
    activities = callbacks.activities #assumes you have some sort of getter/attr_reader on your custom callbacks class

When I get more time I'll document the messages, but for now you can look in ext/rubyfit/rubyfit.c to see what fields are being passed.
