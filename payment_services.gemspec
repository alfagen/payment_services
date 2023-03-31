# frozen_string_literal: true

# Copyright (c) 2018 Danil Pismenny <danil@brandymint.ru>

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'payment_services/version'

Gem::Specification.new do |spec|
  spec.name          = 'payment_services'
  spec.version       = PaymentServices::VERSION
  spec.authors       = ['Danil Pismenny']
  spec.email         = ['danil@brandymint.ru']

  spec.summary       = 'Payment Services modules'
  spec.description   = 'Support for several Payment Services'
  spec.homepage      = ''
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
  # `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'jwt'
  spec.add_dependency 'virtus'
  spec.add_dependency 'workflow'
  spec.add_dependency 'block_io'
  spec.add_dependency 'money-rails'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.61'
end
