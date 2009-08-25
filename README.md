Simple Stats
===

It is a simple statistics library for your application. unlike google
analytics which are more towards web statistics for Websites, This is build specifically
provide tracking and query on your stats for your individual object models such as 
object view and click counting.

### Version
0.1 alpha

TODO
---
  implement log aggregation base on a time interval (1min, 5min), 
  it seems the only way to scale logging in couchdb

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
      simple_stats
    end

    Item.first.track_impression
    Item.first.impressions_count
    => 1

Options
---

#### setup options

- **:as** (:target or :source, default :target)
  config standard tracking or two way tracking
- **:supported_actions** (default : impression/click)
  list of supported actions for stats tracking and reporting, it also supports custom actions
- **:query_prefix** (default : '')
  prefix for reporting methods (item.clicks, item.clicks_count), it defaults to empty string
  for simplicity, you can add a prefix in case there is method name conflict
- **:tracking\_prefix** (default : 'track_')
  prefix for tracking methods (item.track_click)

#### Optional tracking attributes

- remote_ip
- user_agent
- referer
- request_uri
- meta

Example
  
    video.track_view(:user_agent => 'Firefox', :remote_ip => request.ip, :referer => request.referer :meta => {
      :video_hash => '63283ad3d6adf2b616f756de22082000',
      :duration => '3:23',
      :env => request.env          # or event the entire request header
    })


Advanced Example
---

How about two-way tracking between Users and Items, also with custom action tracking

Item is now the tracking target

    class Video < ActiveRecord::Base
      simple_stats :as => :target, :supported_actions => %w(view play pause exit)
    end

User class is now the tracking source

    class User < ActiveRecord::Base
      simple_stats :as => :source, :supported_actions => %w(view play pause exit)
    end

Usage
    
    video = Video.first
    user = User.first
    
    video.track_view
    video.track_view_by(user)
    
    user.track_view_on(video)
    
    # Customize analyic tracking information
    video.track_view(:browser => 'Firefox', :remote_ip => request.ip)

    # Pull all impressions objects (default: today)
    video.views
    
    # Pull all impressions objects of this week
    video.views(7.days.ago ... Time.now)
    
    # Impression count (default: today)
    item.views_count
    
    Item.first.clicks

API
--
javascript api is coming soon

    <script>
        var api_key = "something"
        var stat_for = "Item"
    </script>
    <script src="http://path_to_script/tracking.js"></script>
