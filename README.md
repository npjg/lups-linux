# lups-linux
This small script attempts to use `smbclient` to reach print services at Liberty
University. We use Pharos here, but the script doesn't know anything about that;
it just connects through Samba.

Much of the code comes from the university's macOS [printer install package](https://www.liberty.edu/informationservices/index.cfm?PID=30889#!KB0011132), and the
`smbclient` backend comes from a fellow named [Willem van
Engen](http://willem.engen.nl/).

Note that the script does not use an `authfile`, as Engen does. I prefer to
leave credential management to the GNOME Keyring.

## Supported Distributions
Fedora has been assumed, but cross-distribution support will come soon.
