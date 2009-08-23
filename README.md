Simple Stats
===

It is a simple statistics library for your application. unlike google
analytics which are more towards web statistics for Websites, This is build specifically
provide tracking and query on your stats for your individual object models such as 
object view and click counting.

### Version
0.1 alpha

Features
---

 - It plug into your application to provide tracking for your object models
 - It can track on any target such as Ad, video, Page, Product and Profile
 - Your can optionally provide a tracking source (AdSlut, User, Site, Profile)
 - tracking views and clicks is not enough? you can define custom tracking actions
 such as play/pause/entry/exit/signup.
 - It uses couchdb as storage back-end which means stats can be queried via client 
 side or server side in a RESTful way in JSON . 
 - No tracking logic to pollute your application domain 

Install
---
need collaborator permission
  
    git clone git@github.com:idealian/simple_stats.git
  
    script/plugin install git@github.com:idealian/simple_stats.git
    
Create a configuration file to specify your couchdb server configuration in a
 rails initializer.

*config/initializers/simple_stat.rb*

    COUCH_DB = CouchRest.database!('http://host:5894/simple_stats')

    # Specify your connection
    SimpleStats::Record.use_database COUCH_DB

Example
---

Track basic stats (impressions, clicks) tracking for your items

    class Item < ActiveRecord::Base
      simple_stat :target_prefix => 'stat_', :source_prefix => 'track_'
    end

    Item.first.track_impression
    Item.first.impressions_count
    => 1
    
Advanced Example
---

How about two-way tracking between Users and Items, also with custom action tracking

Item is now the tracking target

    class Item < ActiveRecord::Base
      simple_stat :as => :target, :actions => %w(view click pause play exit)
    end

User class is now the tracking source

    class User < ActiveRecord::Base
      simple_stat :as => :source, :actions => %w(view click pause play exit)
    end

Usage
    
    item = Item.first
    user = User.first
    
    item.track_impression
    item.track_impression_by(user)
    
    user.track_impression_on(item)
    item.track_click(:browser => 'Firefox', :remote_ip => request.ip)

    # Pull all impressions objects (default: today)
    item.impressions
    
    # Pull all impressions objects of this week
    item.impressions(7.days.ago ... Time.now)
    
    # Impression count (default: today)
    item.impressions_count
    
    Item.first.clicks

    
    
    
    <script>
        var api_key = "something"
        var stat_for = "Item"
    </script>
    <script src="http://path_to_script/tracking.js"></script>
