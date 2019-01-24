# archive-org-downloader
A bash script that can be used to download archives from Archive.org

This script makes the downloading of ALL archives found in an archive.org redump easier.

You must set your 'LOGGED_IN_USER' and 'LOGGED_IN_SIG' in the variables section of this script.

Archive.org requires a 'logged-in-user' and 'logged-in-sig' Cookie field passed as a header to be able to access restricted content. You must login using a normal browser to obtain the 'logged-in-sig'.

See https://blog.archive.org/2013/07/04/how-to-use-the-virtual-machine-for-researchers/ 

You can also use a Chrome extension called 'CurlWget' to find the same info.

```
-i, Identifier              The Archive.org identifier
                              You can find this on the Details page of a collection

-e, Archive Extension       Include only the listed extensions (zip, 7z, rar, etc)
                              You can specify multiple by seperating them with |
                              default: ".rar|.zip|.7z" (Must be quoted)

-d, Download directory      The full path directory that items will be downloaded to
                              (/path/to/dir/) (Defaults to current dir)

-L, Load Scrape File        Path to file that contains a scraped list to download
                              Use -s to generate a scrape taht you can edit and load in.
                          
-y, Skip Confirmation       Run script in non-interactive mode (Assumes 'Yes')

-s, Scrape Only             Will only scrape the files found and output to screen.
                              Ignores '-d'

-o, Output Scrape List      Outputs the result of a scrape to the specified file.

-r, Remove When Complete    Removes the item from the list (-L) when completed

-t, Throttle                Cap max speed for download (wget --limit-rate)
                              Expressed in Bytes/s, K, M, and G are recognized. (Example: 3M for 3 MBps)
                              Default set in variable: 10MBps (80 Mbps)
```
