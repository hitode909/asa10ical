# asa10toical

Convert http://asa10.eiga.com/2016/theater/all/ to iCal format.

```
bundle install
wget http://asa10.eiga.com/2016/theater/all/
cat index.html | bundle exec -- ruby asa10ical.rb > a.ics
```
