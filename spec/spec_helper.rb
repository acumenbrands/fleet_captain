$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'capistrano/all'
require 'capistrano/elastic_docker'
require 'rspec'
