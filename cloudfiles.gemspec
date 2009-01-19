# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cloudfiles}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["H. Wade Minter, Rackspace Hosting"]
  s.date = %q{2009-01-19}
  s.description = %q{A Ruby version of the Mosso Cloud Files API.}
  s.email = %q{wade.minter@rackspace.com}
  s.extra_rdoc_files = ["lib/cloudfiles/authentication.rb", "lib/cloudfiles/connection.rb", "lib/cloudfiles/container.rb", "lib/cloudfiles/storage_object.rb", "lib/cloudfiles.rb", "TODO"]
  s.files = ["lib/cloudfiles/authentication.rb", "lib/cloudfiles/connection.rb", "lib/cloudfiles/container.rb", "lib/cloudfiles/storage_object.rb", "lib/cloudfiles.rb", "Rakefile", "test/cf-testunit.rb", "TODO", "Manifest", "cloudfiles.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://www.mosso.com/cloudfiles.jsp}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Cloudfiles"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{cloudfiles}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A Ruby API into Mosso Cloud Files}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<echoe>, [">= 0"])
    else
      s.add_dependency(%q<echoe>, [">= 0"])
    end
  else
    s.add_dependency(%q<echoe>, [">= 0"])
  end
end
