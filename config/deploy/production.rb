require 'socket'
require 'net/ssh/proxy/command'

set :stage, :production

set :app_url,       "http://www.<host>"
set :deploy_to,     "/var/www/<project>"

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
role :app, %w{deploy@<host>}
role :web, %w{deploy@<host>}
role :db,  %w{deploy@<host>}

set :ssh_options, {
  forward_agent: true
}

if Socket.gethostname != "minasanor"
  set :ssh_options, fetch(:ssh_options).merge({
    proxy: Net::SSH::Proxy::Command.new('ssh deploy@minasanor.genero.fi nc %h %p 2> /dev/null')
  })
end
