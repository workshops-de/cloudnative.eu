Jekyll::Hooks.register :site, :after_init do |site|
  require 'rest-client'
  response = RestClient.get('https://workshops.de/api/course/21/events')
  File.write('_data/events/docker-kubernetes-intensiv.json', response.body)
end
