# Gradecraft is a gamified learning management system.


## Current features:
* Badges
* Teams (course-long memberships)
* Groups (single-assignment memberships)
* Assignments
* Assignment Submissions
* Student Dashboard
* Interactive Grade Predictor
* Interactive Course Timeline
* Grading Rubrics
* Export students and final grades
* User analytics
* Team analytics
* Learning analytics suite
* Custom leveling system
* Assignment stats
* Student-logged assignment scoring
* Multipliers (students decide assignment weight)

## Coming soon:
* Assignment Unlocks
* Multi-factor leveling system

## Pre-reqs:
* Ruby 2.2
* PostgreSQL
* MongoDB
* Redis

## Installation instructions for development:
1. Clone repository
1. Run `cp config/database.yml.sample config/database.yml` (within the file, replace ```username``` with your current GitHub username)
1. Run `cp config/mongoid.yml.sample config/mongoid.yml`
1. Run `cp .env.sample .env`
1. Run `bundle install`
1. Run `bundle exec rake db:create`
1. Optional: run `bundle exec rake db:sample`
1. Run `foreman start`
